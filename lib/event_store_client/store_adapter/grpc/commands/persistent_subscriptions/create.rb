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
          class Create
            include Dry::Monads[:result]
            include Configuration

            def call(stream, group, options: {})
              options =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  group_name: group,
                  settings: {
                    resolve_links: true,
                    revision: 2,
                    extra_statistics: true,
                    max_retry_count: 5,
                    min_checkpoint_count: 7,
                    max_checkpoint_count: 8,
                    max_subscriber_count: 9,
                    live_buffer_size: 10,
                    read_batch_size: 11,
                    history_buffer_size: 12,
                    named_consumer_strategy: 1,
                    message_timeout_ms: 100,
                    # message_timeout_ticks: :int64, 4,
                    # checkpoint_after_ticks: :int64, 6,
                    checkpoint_after_ms: 100
                  }
                }
              request = EventStore::Client::PersistentSubscriptions::CreateReq.new(options: options)
              client.create(request)
              Success()
            rescue ::GRPC::AlreadyExists
              Failure(:conflict)
            end

            private

            def client
              EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub.new(
                config.eventstore_url.to_s, :this_channel_is_insecure
              )
            end
          end
        end
      end
    end
  end
end
