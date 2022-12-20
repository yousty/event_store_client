# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module EventStoreClient
  module GRPC
    module Options
      module Streams
        class ReadOptions
          attr_reader :options, :stream_name, :config
          private :options, :stream_name, :config

          # @param stream_name [String]
          # @param options [Hash]
          # @option [String] :direction 'Forwards' or 'Backwards'
          # @option [Integer] :max_count
          # @option [Boolean] :resolve_link_tos
          # @option [Symbol] :from_revision :start or :end. Works only for regular streams.
          # @option [Integer] :from_revision revision number to start from. Remember, that all reads
          #   are inclusive and all subscribes are exclusive. This means if you provide revision
          #   number when reading from stream - the first event will be an event of revision number
          #   you provided. And, when subscribing on stream - the first event will be an event next
          #   to the event of revision number you provided. Works only for regular streams.
          # @option [Symbol] :from_position :start or :end. Works only for $all streams.
          # @option [Hash] :from_position provided a hash with either both :commit_position and
          #   :prepare_position keys or with one of them to define the starting position. Remember,
          #   that all reads are inclusive and all subscribes are exclusive. This means if you
          #   provide position number when reading from stream - the first event will be an event of
          #   position number you provided. And, when subscribing on stream - the first event will
          #   be an event next to the event of position number you provided. Works only for $all
          #   streams. Unlike :from_revision - :commit_position and :prepare_position should contain
          #   values of existing event.
          #   Example:
          #     ```ruby
          #     new('some-stream', from_position: { commit_position: 1024, prepare_position: 1024 })
          #     ```
          # @option [Hash] :filter see
          #   {EventStoreClient::GRPC::Shared::Options::FilterOptions#initialize} for available
          #   values
          # @param config [EventStoreClient::Config]
          def initialize(stream_name, options, config:)
            @stream_name = stream_name
            @options = options
            @config = config
          end

          # @return [Hash] see event_store.client.streams.ReadReq.Options for available options
          def request_options
            request_options = {}
            request_options.merge!(
              Shared::Options::StreamOptions.new(stream_name, options).request_options
            )
            request_options[:read_direction] = options[:direction]
            request_options[:count] = options[:max_count] || config.per_page
            request_options[:resolve_links] = options[:resolve_link_tos]
            request_options.merge!(
              Shared::Options::FilterOptions.new(options[:filter]).request_options
            )
            # This option means how event#id would look like in the response. If you provided
            # :string key, then #id will be a normal UUID string. If you provided :structured
            # key, then #id will be an instance of EventStore::Client::UUID::Structured class.
            # Note: for some reason if you don't provide this option - the request hangs forever
            # Examples:
            #   <EventStore::Client::UUID::Structured:
            #     most_significant_bits: 1266766466329758182,
            #     least_significant_bits: -8366670759139390653>
            #   <EventStore::Client::UUID: string: "f0e1771c-334b-4b8d-ad88-c2024ccbe141">
            request_options[:uuid_option] = { string: EventStore::Client::Empty.new }
            request_options
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize
