# frozen_string_literal: true

require 'dry-monads'
require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Streams
          class Delete
            include Dry::Monads[:result]
            include Configuration

            def call(name)
              opts =
                {
                  stream_identifier: {
                    streamName: name
                  },
                  any: {}
                }

              request = EventStore::Client::Streams::DeleteReq.new(options: opts)
              client.delete(request)
              Success()
            end

            private

            def client
              EventStore::Client::Streams::Streams::Stub.new(
                config.eventstore_url.to_s, :this_channel_is_insecure
              )
            end
          end
        end
      end
    end
  end
end
