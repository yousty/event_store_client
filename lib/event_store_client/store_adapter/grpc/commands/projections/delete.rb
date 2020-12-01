# frozen_string_literal: true

require 'dry-monads'
require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Projections
          class Delete
            include Dry::Monads[:result]
            include Configuration

            def call(name, options: {})
              options =
                {
                  name: name,
                  delete_emitted_streams: true,
                  delete_state_stream: true,
                  delete_checkpoint_stream: true
                }

              request = EventStore::Client::Projections::DeleteReq.new(options: options)
              client.delete(request)
              Success()
            rescue ::GRPC::Unknown => e
              Failure(:not_found) if e.message.include?('OperationFailed')
            end

            private

            def client
              EventStore::Client::Projections::Projections::Stub.new(
                config.eventstore_url.to_s, :this_channel_is_insecure
              )
            end
          end
        end
      end
    end
  end
end
