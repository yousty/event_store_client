# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'

module EventStoreClient
  module GRPC
    module Options
      module Streams
        class ReadOptions
          include Configuration

          attr_reader :options, :stream_name
          private :options, :stream_name

          # @param stream_name [String]
          # @param options [Hash]
          def initialize(stream_name, options)
            @stream_name = stream_name
            @options = options
          end

          # See event_store.client.streams.ReadReq.Options for available options
          # @return [Hash]
          def request_options
            request_options = {}
            request_options.merge!(
              Shared::Options::StreamOptions.new(stream_name, options).request_options
            )
            request_options[:read_direction] = options[:direction]
            request_options[:count] = options[:max_count] || config.per_page
            request_options[:resolve_links] = options[:resolve_link_tos]
            request_options[:no_filter] = EventStore::Client::Empty.new
            # This option means how event#id would look like in the response. If you provided
            # :string key, then #id will be a normal UUID string. If you provided :structured
            # key, then #id will be an instance of EventStore::Client::UUID::Structured class.
            # Note: for some reason if you don't provide this option - the request hangs forever
            # Example:
            #   <EventStore::Client::UUID::Structured: most_significant_bits: 1266766466329758182, least_significant_bits: -8366670759139390653>
            request_options[:uuid_option] = { string: EventStore::Client::Empty.new }
            request_options
          end
        end
      end
    end
  end
end
