# frozen_string_literal: true

module EventStoreClient
  module GRPC
    class Client
      include Configuration
      # Appends given events to the stream
      # @param [String] Stream name to append events to
      # @param [Array](each: EventStoreClient::DeserializedEvent) list of events to publish
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def append_to_stream(stream_name, events, expected_version: nil)
        Commands::Streams::Append.new.call(
          stream_name, events, expected_version: expected_version
        )
      end

      # Softly deletes the given stream
      # @param [String] Stream name to delete
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def delete_stream(stream_name, options: {})
        Commands::Streams::Delete.new.call(
          stream_name, options: options
        )
      end

      # Completely removes the given stream
      # @param [String] Stream name to delete
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def tombstone_stream(stream_name, options: {})
        Commands::Streams::Tombstone.new.call(stream_name, options: options)
      end

      # Reads a page of events from the given stream
      # @param [String] Stream name to read events from
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
      #
      def read(stream_name, options: {})
        Commands::Streams::Read.new.call(stream_name, options: options)
      end

      # Reads all events from the given stream
      # @param [String] Stream name to read events from
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
      #
      def read_all_from_stream(stream_name, options: {})
        Commands::Streams::ReadAll.new.call(stream_name, options: options)
      end

      # Creates the subscription for the given stream
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def subscribe_to_stream(subscription, options: {})
        join_streams(subscription.name, subscription.observed_streams)
        Commands::PersistentSubscriptions::Create.new.call(
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
        # TODO: based on implementation of http adapter,
        # implement the linking events mechanism for GRPC
      end

      # Runs the persistent subscription indeinitely
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return - Nothing, it is a blocking operation, yields the given block with event instead
      #
      def listen(subscription, options: {})
        consume_feed(subscription, options: options) do |event|
          yield event if block_given?
        end
      rescue StandardError => e
        config.error_handler&.call(e)
      end

      private

      # Joins multiple streams into the new one under the given name
      # @param [String] Name of the stream containing the ones to join
      # @param [Array] (each: String) list of streams to join together
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def join_streams(name, streams)
        Commands::Projections::Create.new.call(name, streams)
        Commands::Projections::Update.new.call(name, streams)
      end

      # @api private
      # Consumes the new events from the subscription
      # @param [EventStoreClient::Subscription] subscription to observe
      # @param options [Hash] additional options to the request
      # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
      #
      def consume_feed(subscription, options: {})
        Commands::PersistentSubscriptions::Read.new.call(
          subscription.stream, subscription.name, options: options
        ) do |event|
          yield event if block_given?
        end
      end
    end
  end
end
