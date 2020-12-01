# frozen_string_literal: true

require 'dry-monads'
require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/settings_schema'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module PersistentSubscriptions
          class Update < Command
            use_request EventStore::Client::PersistentSubscriptions::UpdateReq
            use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

            # Creates persistent subscription in a given group
            # @param [String] name of the subscription stream to update
            # @param [String] name of the subscription group
            # @param [Hash] options - additional settings to be set on subscription.
            #   Refer to EventStoreClient::StoreAdapter::GRPC::Commands::SettingsSchema
            #   for detailed attributes schema
            # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure]
            #
            def call(stream, group, options: {})
              schema = SettingsSchema.call(options)
              return Failure(schema.errors) if schema.failure?

              opts =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  group_name: group,
                  settings: schema.to_h
                }
              service.update(request.new(options: opts))
              Success()
            rescue ::GRPC::Unknown => e
              return Failure(:not_found) if e.message.include?('DoesNotExist')
              raise e
            end
          end
        end
      end
    end
  end
end
