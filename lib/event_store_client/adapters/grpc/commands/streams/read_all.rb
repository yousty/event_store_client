# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/projections_pb'
require 'event_store_client/adapters/grpc/generated/projections_services_pb'

require 'event_store_client/configuration'
require 'event_store_client/adapters/grpc/commands/command'
require 'event_store_client/adapters/grpc/commands/streams/read'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class ReadAll < Command
          include Configuration

          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          def call(stream_name, options: {})
            start ||= options[:start] || 0
            count ||= options[:count] || 20
            events = []

            loop do
              res = Read.new.call(
                stream_name, options: options.merge(start: start, count: count)
              )
              break if res.failure?
              break if (entries = res.value!).empty?

              events += entries
              start += count
            end

            Success(events)
          end
        end
      end
    end
  end
end
