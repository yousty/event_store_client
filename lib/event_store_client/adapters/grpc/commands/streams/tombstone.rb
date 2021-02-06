# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/projections_pb.rb'
require 'event_store_client/adapters/grpc/generated/projections_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Tombstone < Command
          use_request EventStore::Client::Streams::TombstoneReq
          use_service EventStore::Client::Streams::Streams::Stub

          def call(name, options: {})
            opts =
              {
                stream_identifier: {
                  streamName: name
                },
                any: {}
              }

            service.tombstone(request.new(options: opts), metadata: metadata)
            Success()
          rescue ::GRPC::FailedPrecondition
            Failure(:not_found)
          end
        end
      end
    end
  end
end
