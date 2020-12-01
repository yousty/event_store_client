# frozen_string_literal: true

require 'dry-monads'
require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module PersistentSubscriptions
          class Delete
            include Dry::Monads[:result]

            # stream_name, subscription_name, stats: true, start_from: 0, retries: 5

            def call(uri, stream, group, options: {})
              options =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  group_name: group
                }
              request = EventStore::Client::PersistentSubscriptions::DeleteReq.new(options: options)
              client(uri).delete(request)
              Success()
            rescue ::GRPC::NotFound => e
              Failure(:not_found)
            end

            private

            def client(uri)
              EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub.new(
                uri.to_s, :this_channel_is_insecure
              )
            end
          end
        end
      end
    end
  end
end
