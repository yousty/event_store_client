# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/projections_pb'
require 'event_store_client/adapters/grpc/generated/projections_services_pb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Delete < Command
          use_request EventStore::Client::Streams::DeleteReq
          use_service EventStore::Client::Streams::Streams::Stub

          def call(name, options: {}) # rubocop:disable Lint/UnusedMethodArgument
            opts =
              {
                stream_identifier: {
                  stream_name: name
                },
                any: {}
              }

            service.delete(request.new(options: opts), metadata: metadata)
            Success()
          rescue ::GRPC::FailedPrecondition
            Failure(:not_found)
          end
        end
      end
    end
  end
end
