# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/persistent_pb.rb'
require 'event_store_client/adapters/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module PersistentSubscriptions
        class Delete < Command
          use_request EventStore::Client::PersistentSubscriptions::DeleteReq
          use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

          def call(stream, group)
            opts =
              {
                stream_identifier: {
                  streamName: stream
                },
                group_name: group
              }
            service.delete(request.new(options: opts), metadata: metadata)
            Success()
          rescue ::GRPC::NotFound
            Failure(:not_found)
          end
        end
      end
    end
  end
end
