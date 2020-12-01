# frozen_string_literal: true

require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module PersistentSubscriptions
          class Delete < Command
            use_request EventStore::Client::PersistentSubscriptions::DeleteReq
            use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

            def call(stream, group, options: {})
              opts =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  group_name: group
                }
              service.delete(request.new(options: opts))
              Success()
            rescue ::GRPC::NotFound => e
              Failure(:not_found)
            end
          end
        end
      end
    end
  end
end
