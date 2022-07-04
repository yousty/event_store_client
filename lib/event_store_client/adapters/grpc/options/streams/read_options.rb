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
            request_options.merge!(stream_name == "$all" ? all_stream : stream)
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

          private

          # @return [Hash]
          #   Examples:
          #   ```ruby
          #   { all: { start: EventStore::Client::Empty.new } }
          #   ```
          #   ```ruby
          #   { all: { end: EventStore::Client::Empty.new } }
          #   ```
          #   ```ruby
          #   { all: { position: { commit_position: 1, prepare_position: 1 } } }
          #   ```
          def all_stream
            position_opt =
              case options[:from_position]
              when :start, :end
                { options[:from_position] => EventStore::Client::Empty.new }
              when Hash
                { position: options[:from_position] }
              else
                { start: EventStore::Client::Empty.new }
              end
            { all: position_opt }
          end

          # @return [Hash]
          #   Examples:
          #   ```ruby
          #   { stream: {
          #       start: EventStore::Client::Empty.new,
          #       stream_identifier: { stream_name: 'some-stream' }
          #     }
          #   }
          #   ```
          #   ```ruby
          #   { stream: {
          #       end: EventStore::Client::Empty.new,
          #       stream_identifier: { stream_name: 'some-stream' }
          #     }
          #   }
          #   ```
          #   ```ruby
          #   { stream: { revision: 1, stream_identifier: { stream_name: 'some-stream' } } }
          #   ```
          def stream
            revision_opt =
              case options[:from_revision]
              when :start, :end
                { options[:from_revision] => EventStore::Client::Empty.new }
              when Integer
                { revision: options[:from_revision] }
              else
                { start: EventStore::Client::Empty.new }
              end
            { stream: revision_opt.merge(stream_identifier: { stream_name: stream_name }) }
          end
        end
      end
    end
  end
end
