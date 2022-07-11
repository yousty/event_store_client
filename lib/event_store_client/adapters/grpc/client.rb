# frozen_string_literal: true

module EventStoreClient
  module GRPC
    class Client < EventStoreClient::Client
      include Configuration

      # @param stream_name [String]
      # @param events [Array<EventStoreClient::DeserializedEvent>]
      # @param options [Hash]
      # @option options [Integer] :expected_revision provide your own revision number
      # @option options [String] :expected_revision provide one of next values: 'any', 'no_stream'
      #   or 'stream_exists'
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure, nil]
      #   Returns nil if no request was performed. Returns monads' Success/Failure in case whether
      #   request was performed
      def append_to_stream(stream_name, events, options: {}, credentials: {})
        Commands::Streams::Append.new(credentials).call(
          stream_name, events, options: options
        )
      end

      # @param stream_name [String]
      # @param skip_deserialization [Boolean]
      # @param skip_decryption [Boolean]
      # @param options [Hash] request options
      # @option options [String] :direction read direction - 'Forwards' or 'Backwards'
      # @option options [Integer, Symbol] :from_revision. If number is provided - it is threaded
      #   as starting revision number. Alternatively you can provide :start or :end value to
      #   define a stream revision. **Use this option when stream name is a normal stream name**
      # @option options [Hash, Symbol] :from_position. If hash is provided - you should supply
      #   it with :commit_position and/or :prepare_position keys. Alternatively you can provide
      #   :start or :end value to define a stream position. **Use this option when stream name
      #   is "$all"**
      # @option options [Integer] :max_count max number of events to return in one response
      # @option options [Boolean] :resolve_link_tos When using projections to create new events you
      #   can set whether the generated events are pointers to existing events. Setting this value
      #   to true tells EventStoreDB to return the event as well as the event linking to it.
      # @option options [Hash] :filter provide it to filter events when reading from $all. You can
      #   either filter by stream name or filter by event type. Filtering can be done by using
      #   Regexp or by a string.
      #   Examples:
      #     ```ruby
      #     # Include events only from streams which names start from 'some-stream-1' and
      #     # 'some-stream-2'
      #     { filter: { stream_identifier: { prefix: ['some-stream-1', 'some-stream-2'] } } }
      #
      #     # Include events only from streams which names end with digit
      #     { filter: { stream_identifier: { regex: /\d$/.to_s } } }
      #
      #     # Include events which start from 'some-event-1' and 'some-event-2'
      #     { filter: { event_type: { prefix: ['some-event-1', 'some-event-2'] } } }
      #
      #     # Include events which names end with digit
      #     { filter: { event_type: { regex: /\d$/.to_s } } }
      #     ```
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @yield [EventStore::Client::Streams::ReadReq::Options] yields request options right
      #   before sending the request. You can extend it with your own options, not covered in
      #   the default implementation.
      #   Example:
      #     ```ruby
      #     read('$all') do |opts|
      #       opts.filter = EventStore::Client::Streams::ReadReq::Options::FilterOptions.new(
      #         { stream_identifier: { prefix: ['as'] }, count: EventStore::Client::Empty.new }
      #       )
      #     end
      #   ```
      # @return [Dry::Monads::Success, Dry::Monads::Failure]
      def read(stream_name, options: {}, skip_deserialization: config.skip_deserialization,
               skip_decryption: config.skip_decryption, credentials: {}, &blk)
        Commands::Streams::Read.new(credentials).call(
          stream_name,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption,
          &blk
        )
      end

      # @see {#read} for available params
      # @return [Enumerator] enumerator will yield Dry::Monads::Success or Dry::Monads::Failure on
      #   each iteration
      def read_paginated(stream_name, options: {}, credentials: {},
                         skip_deserialization: config.skip_deserialization,
                         skip_decryption: config.skip_decryption, &blk)
        Commands::Streams::ReadPaginated.new(credentials).call(
          stream_name,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption,
          &blk
        )
      end

      # Refs https://developers.eventstore.com/server/v5/streams.html#hard-delete
      # @param stream_name [String]
      # @param options [Hash]
      # @option options [Integer, String] :expected_revision provide your own revision number.
      #   Alternatively you can provide one of next values: 'any', 'no_stream' or 'stream_exists'.
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @yield [EventStore::Client::Streams::TombstoneReq::Options] yields request options right
      #   before sending the request. You can override them in your own way.
      #   Example:
      #     ```ruby
      #     delete_stream('stream_name') do |opts|
      #       opts.stream_identifier.stream_name = 'overridden-stream-name'
      #     end
      #     ```
      # @return [Dry::Monads::Success, Dry::Monads::Failure]
      def hard_delete_stream(stream_name, options: {}, credentials: {}, &blk)
        Commands::Streams::HardDelete.new(credentials).call(stream_name, options: options, &blk)
      end

      # Refs https://developers.eventstore.com/server/v5/streams.html#soft-delete-and-truncatebefore
      # @param stream_name [String]
      # @param options [Hash]
      # @option options [Integer, String] :expected_revision provide your own revision number.
      #   Alternatively you can provide one of next values: 'any', 'no_stream' or 'stream_exists'.
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @yield [EventStore::Client::Streams::DeleteReq::Options] yields request options right
      #   before sending the request. You can override them in your own way.
      #   Example:
      #     ```ruby
      #     delete_stream('stream_name') do |opts|
      #       opts.stream_identifier.stream_name = 'overridden-stream-name'
      #     end
      #     ```
      # @return [Dry::Monads::Success, Dry::Monads::Failure]
      def delete_stream(stream_name, options: {}, credentials: {}, &blk)
        Commands::Streams::Delete.new(credentials).call(stream_name, options: options, &blk)
      end

      # Subscribe to the given stream and listens for events. Note, that it will block execution of
      #   current stack. If you want to do it asynchronous - consider putting it out of current
      #   thread.
      # @param stream_name [String]
      # @param handler [#call] whenever new event arrives - #call method of your handler will be
      #   called with the response passed into it
      # @param skip_deserialization [Boolean]
      # @param skip_decryption [Boolean]
      # @param options [Hash] request options
      # @option options [String] :direction read direction - 'Forwards' or 'Backwards'
      # @option options [Integer, Symbol] :from_revision. If number is provided - it is threaded
      #   as starting revision number. Alternatively you can provide :start or :end value to
      #   define a stream revision. **Use this option when stream name is a normal stream name**
      # @option options [Hash, Symbol] :from_position. If hash is provided - you should supply
      #   it with :commit_position and/or :prepare_position keys. Alternatively you can provide
      #   :start or :end value to define a stream position. **Use this option when stream name
      #   is "$all"**
      # @option options [Boolean] :resolve_link_tos When using projections to create new events you
      #   can set whether the generated events are pointers to existing events. Setting this value
      #   to true tells EventStoreDB to return the event as well as the event linking to it.
      # @option options [Hash] :filter provide it to filter events when subscribing to $all. You can
      #   either filter by stream name or filter by event type. Filtering can be done by using
      #   Regexp or by a string.
      #   Examples:
      #     ```ruby
      #     # Include events only from streams which names start from 'some-stream-1' and
      #     # 'some-stream-2'
      #     { filter: { stream_identifier: { prefix: ['some-stream-1', 'some-stream-2'] } } }
      #
      #     # Include events only from streams which names end with digit
      #     { filter: { stream_identifier: { regex: /\d$/.to_s } } }
      #
      #     # Include events which start from 'some-event-1' and 'some-event-2'
      #     { filter: { event_type: { prefix: ['some-event-1', 'some-event-2'] } } }
      #
      #     # Include events which names end with digit
      #     { filter: { event_type: { regex: /\d$/.to_s } } }
      #     ```
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @yield [EventStore::Client::Streams::ReadReq::Options] yields request options right
      #   before sending the request. You can extend it with your own options, not covered in
      #   the default implementation.
      #   Example:
      #     ```ruby
      #     subscribe_to_stream('$all', handler: proc { |response| puts response }) do |opts|
      #       opts.filter = EventStore::Client::Streams::ReadReq::Options::FilterOptions.new(
      #         { stream_identifier: { prefix: ['as'] }, max: 100 }
      #       )
      #     end
      #     ```
      # @return [Dry::Monads::Success, Dry::Monads::Failure]
      def subscribe_to_stream(stream_name, handler:, options: {}, credentials: {},
                              skip_deserialization: config.skip_deserialization,
                              skip_decryption: config.skip_decryption, &blk)
        Commands::Streams::Subscribe.new(credentials).call(
          stream_name,
          handler: handler,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption,
          &blk
        )
      end

      # This method acts the same as #subscribe_to_stream with the only exception that it subscribes
      # to $all stream
      # @see #subscribe_to_stream
      def subscribe_to_all(handler:, options: {}, credentials: {},
                              skip_deserialization: config.skip_deserialization,
                              skip_decryption: config.skip_decryption, &blk)
        Commands::Streams::Subscribe.new(credentials).call(
          '$all',
          handler: handler,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption,
          &blk
        )
      end
    end
  end
end

# module EventStoreClient
#   module GRPC
#     class Client
#       include Configuration
#       # Appends given events to the stream
#       # @param [String] Stream name to append events to
#       # @param [Array](each: EventStoreClient::DeserializedEvent) list of events to publish
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def append_to_stream(stream_name, events, options: {})
#         Commands::Streams::Append.new.call(
#           stream_name, events, options: options
#         )
#       end

#       # Softly deletes the given stream
#       # @param [String] Stream name to delete
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def delete_stream(stream_name, options: {})
#         Commands::Streams::Delete.new.call(
#           stream_name, options: options
#         )
#       end

#       # Completely removes the given stream
#       # @param [String] Stream name to delete
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def tombstone_stream(stream_name, options: {})
#         Commands::Streams::Tombstone.new.call(stream_name, options: options)
#       end

#       # Reads a page of events from the given stream
#       # @param [String] Stream name to read events from
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
#       #
#       def read(stream_name, options: {})
#         Commands::Streams::Read.new.call(stream_name, options: options)
#       end

#       # Reads all events from the given stream
#       # @param [String] Stream name to read events from
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success with returned events or Dry::Monads::Result::Failure
#       #
#       def read_all_from_stream(stream_name, options: {})
#         Commands::Streams::ReadAll.new.call(stream_name, options: options)
#       end

#       # Creates the subscription for the given stream
#       # @param [EventStoreClient::Subscription] subscription to observe
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def subscribe_to_stream(subscription, options: {})
#         join_streams(subscription.name, subscription.observed_streams)
#         Commands::PersistentSubscriptions::Create.new.call(
#           subscription.stream,
#           subscription.name,
#           options: options
#         )
#       end

#       # Links given events with the given stream
#       # @param [String] Stream name to link events to
#       # @param [Array](each: EventStoreClient::DeserializedEvent) a list of events to link
#       # @param expected_version [Integer] expected number of events in the stream
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def link_to(stream_name, events, options: {})
#         Commands::Streams::LinkTo.new.call(stream_name, events, options: options)
#       end

#       # Runs the persistent subscription indeinitely
#       # @param [EventStoreClient::Subscription] subscription to observe
#       # @param options [Hash] additional options to the request
#       # @return - Nothing, it is a blocking operation, yields the given block with event instead
#       #
#       def listen(subscription, options: {})
#         consume_feed(subscription, options: options) do |event|
#           begin
#             yield event if block_given?
#           rescue StandardError => e
#             config.error_handler&.call(e)
#           end
#         end
#       end

#       # Subscribe to a stream
#       # @param options [Hash] additional options to the request
#       # @return - Nothing, it is a blocking operation, yields the given block with event instead
#       #
#       def subscribe(options = {})
#         Commands::Streams::Subscribe.new.call(options) do |event|
#           yield event if block_given?
#         end
#       rescue StandardError => e
#         config.error_handler&.call(e)
#       end

#       private

#       # Joins multiple streams into the new one under the given name
#       # @param [String] Name of the stream containing the ones to join
#       # @param [Array] (each: String) list of streams to join together
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def join_streams(name, streams)
#         res = Commands::Projections::Create.new.call(name, streams)
#         return if res.success?

#         Commands::Projections::Update.new.call(name, streams)
#       end

#       # @api private
#       # Consumes the new events from the subscription
#       # @param [EventStoreClient::Subscription] subscription to observe
#       # @param options [Hash] additional options to the request
#       # @return Dry::Monads::Result::Success or Dry::Monads::Result::Failure
#       #
#       def consume_feed(subscription, options: {})
#         Commands::PersistentSubscriptions::Read.new.call(
#           subscription.stream, subscription.name, options: options
#         ) do |event|
#           yield event if block_given?
#         end
#       end
#     end
#   end
# end
