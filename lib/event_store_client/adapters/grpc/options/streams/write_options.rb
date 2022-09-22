# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'

module EventStoreClient
  module GRPC
    module Options
      module Streams
        class WriteOptions
          attr_reader :stream_name, :options
          private :stream_name, :options

          # @param stream_name [String]
          # @param options [Hash]
          # @option [Integer] :expected_revision
          # @option [Symbol] :expected_revision either :any, :no_stream or :stream_exists
          def initialize(stream_name, options)
            @stream_name = stream_name
            @options = options
          end

          # @return [Hash] see event_store.client.streams.AppendReq.Options for available options
          def request_options
            revision_opt =
              case options[:expected_revision]
              when :any, :no_stream, :stream_exists
                { options[:expected_revision] => EventStore::Client::Empty.new }
              when Integer
                { revision: options[:expected_revision] }
              else
                { any: EventStore::Client::Empty.new }
              end
            revision_opt.merge(stream_identifier: { stream_name: stream_name })
          end
        end
      end
    end
  end
end
