# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Options
        class FilterOptions
          attr_reader :options
          private :options

          # See event_store.client.streams.ReadReq.Options.FilterOptions in streams_pb.rb generated
          # file for more info(for persisted subscription the structure is the same)
          # @param filter_options [Hash, nil]
          # @option [Integer] :checkpointIntervalMultiplier
          # @option [Integer] :max
          # @option [Boolean] :count
          # @option [Hash] :stream_identifier filter events by stream name using Regexp or String.
          #   Examples:
          #   ```ruby
          #   # Return events streams names of which end with number
          #   new(stream_identifier: { regex: /.*\d$/.to_s })
          #   # Return events streams names of which start from 'some-stream-1' or 'some-stream-2'
          #   # strings
          #   new(stream_identifier: { prefix: ['some-stream-1', 'some-stream-2'] })
          #   ```
          # @option [Hash] :event_type filter events by event name using Regexp or String.
          #   Examples:
          #   ```ruby
          #   # Return events names of which end with number
          #   new(event_type: { regex: /.*\d$/.to_s })
          #   # Return events names of which start from 'some-event-1' or 'some-event-2'
          #   # strings
          #   new(event_type: { prefix: ['some-event-1', 'some-event-2'] })
          #   ```
          def initialize(filter_options)
            @options = filter_options
          end

          # See :filter_option in persistent_pb.rb or in streams_pb.rb generated files
          # @return [Hash]
          def request_options
            request_options = {}
            case options
            in { stream_identifier: { regex: String } } | { stream_identifier: { prefix: Array } } |
              { event_type: { regex: String } } | { event_type: { prefix: Array } }
              request_options[:filter] = options
              add_window_options(request_options)
            else
              request_options[:no_filter] = EventStore::Client::Empty.new
            end
            request_options
          end

          private

          # Define how frequently "checkpoint" event should be produced. Its value is calculated
          # by multiplying max by checkpointIntervalMultiplier.
          #   Example:
          #     Given max 32 and multiplier 2 - "checkpoint" event will be produced on each
          #     64' event
          # These options are only useful when subscribing to the stream
          # @return [void]
          def add_window_options(request_options)
            request_options[:filter][:max] ||= 100
            if request_options[:filter][:count]
              request_options[:filter][:count] = EventStore::Client::Empty.new
            end
            request_options[:filter][:checkpointIntervalMultiplier] ||= 1
          end
        end
      end
    end
  end
end
