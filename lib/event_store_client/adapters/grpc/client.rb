# frozen_string_literal: true

# rubocop:disable Layout/LineLength, Metrics/ParameterLists

module EventStoreClient
  module GRPC
    class Client
      attr_reader :config

      # @param config [EventStoreClient::Config]
      def initialize(config)
        @config = config
      end

      # @param stream_name [String]
      # @param events_or_event [EventStoreClient::DeserializedEvent, Array<EventStoreClient::DeserializedEvent>]
      # @param options [Hash]
      # @option options [Integer] :expected_revision provide your own revision number
      # @option options [String] :expected_revision provide one of next values: 'any', 'no_stream'
      #   or 'stream_exists'
      # @param credentials [Hash]
      # @option credentials [String] :username override authentication username
      # @option credentials [String] :password override authentication password
      # @yield [EventStore::Client::Streams::AppendReq, EventStore::Client::Streams::AppendReq]
      #   yields options and proposed message option right before sending the request. You can
      #   extend it with your own options, not covered in the default implementation.
      #   Example:
      #     ```ruby
      #     append_to_stream('some-stream', event) do |req_opts, proposed_msg_opts|
      #       puts req_opts.options
      #       puts proposed_msg_opts.proposed_message
      #     end
      #   ```
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure, Array<Dry::Monads::Result::Success, Dry::Monads::Result::Failure>]
      #   Returns monads' Success/Failure in case whether request was performed.
      def append_to_stream(stream_name, events_or_event, options: {}, credentials: {}, &blk)
        if events_or_event.is_a?(Array)
          Commands::Streams::AppendMultiple.new(config: config, **credentials).call(
            stream_name, events_or_event, options: options
          )
        else
          Commands::Streams::Append.new(config: config, **credentials).call(
            stream_name, events_or_event, options: options, &blk
          )
        end
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
        Commands::Streams::Read.new(config: config, **credentials).call(
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
        Commands::Streams::ReadPaginated.new(config: config, **credentials).call(
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
        Commands::Streams::HardDelete.
          new(config: config, **credentials).
          call(stream_name, options: options, &blk)
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
        Commands::Streams::Delete.
          new(config: config, **credentials).
          call(stream_name, options: options, &blk)
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
        Commands::Streams::Subscribe.new(config: config, **credentials).call(
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
        Commands::Streams::Subscribe.new(config: config, **credentials).call(
          '$all',
          handler: handler,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption,
          &blk
        )
      end

      # Links event from one stream into another stream. You can later access it by providing
      # :resolve_link_tos option when reading from a stream. If you provide an event that does not
      # present in EventStore database yet - its data will not be appended properly to the stream,
      # thus, making it look as a malformed event.
      # @see #append_to_stream for available params and returned value
      def link_to(stream_name, events_or_event, options: {}, credentials: {}, &blk)
        if events_or_event.is_a?(Array)
          Commands::Streams::LinkToMultiple.new(config: config, **credentials).call(
            stream_name,
            events_or_event,
            options: options,
            &blk
          )
        else
          Commands::Streams::LinkTo.new(config: config, **credentials).call(
            stream_name,
            events_or_event,
            options: options,
            &blk
          )
        end
      end

      # @param credentials [Hash]
      # @option credentials [String] :username
      # @option credentials [String] :password
      # @return [Dry::Monads::Success, Dry::Monads::Failure]
      def cluster_info(credentials: {})
        Commands::Gossip::ClusterInfo.new(config: config, **credentials).call
      end
    end
  end
end
# rubocop:enable Layout/LineLength, Metrics/ParameterLists
