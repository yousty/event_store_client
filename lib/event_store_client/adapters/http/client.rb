# frozen_string_literal: true

require 'event_store_client/adapters/http/connection'
require 'dry/monads/result'

module EventStoreClient
  module HTTP
    class Client
      include Configuration
      include Dry::Monads[:result]
      # Appends given events to the stream
      # @param [String] Stream name to append events to
      # @param [Array](each: EventStoreClient::DeserializedEvent) list of events to publish
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def append_to_stream(stream_name, events, options: {})
        Commands::Streams::Append.new(connection).call(
          stream_name, events, options: options
        )
      end

      # Softly deletes the given stream
      # @param [String] Stream name to delete
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def delete_stream(stream_name, options: {})
        Commands::Streams::Delete.new(connection).call(
          stream_name, options: options
        )
      end

      # Completely removes the given stream
      # @param [String] Stream name to delete
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def tombstone_stream(stream_name, options: {})
        Commands::Streams::Tombstone.new(connection).call(
          stream_name, options: options
        )
      end

      # Reads a page of events from the given stream
      # @param [String] Stream name to read events from
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
      #
      def read(stream_name, options: {})
        Commands::Streams::Read.new(connection).call(
          stream_name, options: options
        )
      end

      # Reads all events from the given stream
      # @param [String] Stream name to read events from
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
      #
      def read_all_from_stream(stream_name, options: {})
        start ||= options[:start] || 0
        count ||= options[:count] || 20
        events = []
        failed_requests_count = 0

        while failed_requests_count < 3
          res = read(stream_name, options: options.merge(start: start, count: count))
          if res.failure?
            failed_requests_count += 1
          else
            break if res.value!.empty?
            events += res.value!
            failed_requests_count = 0
            start += count
          end
        end
        return Failure(:connection_failed) if failed_requests_count >= 3

        Success(events)
      end

      # Creates the subscription for the given stream
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def subscribe_to_stream(subscription, options: {})
        join_streams(subscription.name, subscription.observed_streams)
        Commands::PersistentSubscriptions::Create.new(connection).call(
          subscription.stream,
          subscription.name,
          options: options
        )
      end

      # Links given events with the given stream
      # @param [String] Stream name to link events to
      # @param [Array](each: EventStoreClient::DeserializedEvent) a list of events to link
      # @param expected_version [Integer] expected number of events in the stream
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def link_to(stream_name, events, options: {})
        Commands::Streams::LinkTo.new(connection).call(
          stream_name, events, options: options
        )
      end

      # Runs the persistent subscription indeinitely
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return - Nothing, it is a blocking operation, yields the given block with event instead
      #
      def listen(subscription, options: {})
        loop do
          begin
            consume_feed(subscription) do |event|
              yield event if block_given?
            end
          rescue StandardError => e
            config.error_handler&.call(e)
          end
          sleep(options[:interval] || 5) # wait for events to be processed
        end
      end

      private

      attr_reader :connection

      def initialize
        @connection = Connection.new(config.eventstore_url)
      end

      # @api private
      # Joins multiple streams into the new one under the given name
      # @param [String] Name of the stream containing the ones to join
      # @param [Array] (each: String) list of streams to join together
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def join_streams(name, streams, options: {})
        Commands::Projections::Create.new(connection).call(name, streams, options: options)
      end

      # @api private
      # Consumes the new events from the subscription
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def consume_feed(subscription, options: {})
        Commands::PersistentSubscriptions::Read.new(connection).call(
          subscription.stream, subscription.name, options: options
        ) do |event|
          yield event if block_given?
        end
      end
    end
  end
end
