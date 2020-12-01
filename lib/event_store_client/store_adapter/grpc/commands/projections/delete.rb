# frozen_string_literal: true

require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Projections
          class Delete < Command
            use_request EventStore::Client::Projections::DeleteReq
            use_service EventStore::Client::Projections::Projections::Stub

            def call(name, options: {})
              options =
                {
                  name: name,
                  delete_emitted_streams: true,
                  delete_state_stream: true,
                  delete_checkpoint_stream: true
                }

              service.delete(request.new(options: options))
              Success()
            rescue ::GRPC::Unknown => e
              Failure(:not_found) if e.message.include?('OperationFailed')
            end
          end
        end
      end
    end
  end
end
