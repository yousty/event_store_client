# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Options
        class StreamOptions
          attr_reader :stream_name, :options
          private :stream_name, :options

          # @param stream_name [String]
          # @param options [Hash]
          # @option options [Integer, Symbol] :from_revision. If number is provided - it is threaded
          #   as starting revision number. Alternatively you can provide :start or :end value to
          #   define a stream revision. **Use this option when stream name is a normal stream name**
          # @option options [Hash, Symbol] :from_position. If hash is provided - you should supply
          #   it with :commit_position and/or :prepare_position keys. Alternatively you can provide
          #   :start or :end value to define a stream position. **Use this option when stream name
          #   is "$all"**
          def initialize(stream_name, options)
            @stream_name = stream_name
            @options = options
          end

          # @return [Hash]
          def request_options
            stream_name == "$all" ? all_stream : stream
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
