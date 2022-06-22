# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/persistent_pb'
require 'event_store_client/adapters/grpc/generated/persistent_services_pb'

require 'event_store_client/adapters/grpc/commands/command'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/settings_schema'

module EventStoreClient
  module GRPC
    module Commands
      module PersistentSubscriptions
        class Create < Command
          use_request EventStore::Client::PersistentSubscriptions::CreateReq
          use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

          # Creates persistent subscription in a given group
          # @param stream [String] name of the stream to subscribe
          # @param group [String] name of the subscription group
          # @param [Hash] options - additional settings to be set on subscription.
          #   Refer to SettingsSchema for detailed attributes allowed
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

            service.create(request.new(options: opts), metadata: metadata)
            Success()
          rescue ::GRPC::AlreadyExists
            Failure(:conflict)
          end
        end
      end
    end
  end
end
