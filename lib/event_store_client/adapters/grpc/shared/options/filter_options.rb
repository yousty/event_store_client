# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'

module EventStoreClient
  module GRPC
    module Shared
      module Options
        class FilterOptions
          attr_reader :options
          private :options

          # @param filter_options [Hash]
          def initialize(filter_options)
            @options = filter_options
          end

          # See :filter_option in persistent_pb.rb or in streams_pb.rb generated files
          # @return [Hash]
          def request_options
            request_options = {}
            case options
            in { stream_identifier: { regex: String } } | { stream_identifier: { prefix: Array } }
              request_options[:filter] = options
              add_window_options(request_options)
            in { event_type: { regex: String } } | { event_type: { prefix: Array } }
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
            request_options[:filter][:checkpointIntervalMultiplier] ||= 1
          end
        end
      end
    end
  end
end
