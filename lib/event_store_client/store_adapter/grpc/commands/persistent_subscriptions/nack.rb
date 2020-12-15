# frozen_string_literal: true

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
          class Read < Command
            use_request EventStore::Client::PersistentSubscriptions::ReadReq
            use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

            # Read given persistent subscription
            # @param [String] name of the stream to subscribe
            # @param [String] name of the subscription group
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

              service.read(request.new(options: opts))
              Success()
            rescue ::GRPC::AlreadyExists
              Failure(:conflict)
            end
          end
        end
      end
    end
  end
end



# add_message "event_store.client.persistent_subscriptions.ReadReq" do
#   oneof :content do
#     optional :nack, :message, 3, "event_store.client.persistent_subscriptions.ReadReq.Nack"
#   end
# end

# add_message "event_store.client.persistent_subscriptions.ReadReq.Options.UUIDOption" do
#   oneof :content do
#     optional :structured, :message, 1, "event_store.client.shared.Empty"
#     optional :string, :message, 2, "event_store.client.shared.Empty"
#   end
# end

# add_message "event_store.client.persistent_subscriptions.ReadReq.Nack" do
#   optional :id, :bytes, 1
#   repeated :ids, :message, 2, "event_store.client.shared.UUID"
#   optional :action, :enum, 3, "event_store.client.persistent_subscriptions.ReadReq.Nack.Action"
#   optional :reason, :string, 4
# end
# add_enum "event_store.client.persistent_subscriptions.ReadReq.Nack.Action" do
#   value :Unknown, 0
#   value :Park, 1
#   value :Retry, 2
#   value :Skip, 3
#   value :Stop, 4
# end



# # Read persistent Subscription response
# #
# add_message "event_store.client.persistent_subscriptions.ReadResp" do
#   oneof :content do
#     optional :event, :message, 1, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent"
#     optional :subscription_confirmation, :message, 2, "event_store.client.persistent_subscriptions.ReadResp.SubscriptionConfirmation"
#   end
# end
# add_message "event_store.client.persistent_subscriptions.ReadResp.ReadEvent" do
#   optional :event, :message, 1, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent"
#   optional :link, :message, 2, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent"
#   oneof :position do
#     optional :commit_position, :uint64, 3
#     optional :no_position, :message, 4, "event_store.client.shared.Empty"
#   end
#   oneof :count do
#     optional :retry_count, :int32, 5
#     optional :no_retry_count, :message, 6, "event_store.client.shared.Empty"
#   end
# end
# add_message "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent" do
#   optional :id, :message, 1, "event_store.client.shared.UUID"
#   optional :stream_identifier, :message, 2, "event_store.client.shared.StreamIdentifier"
#   optional :stream_revision, :uint64, 3
#   optional :prepare_position, :uint64, 4
#   optional :commit_position, :uint64, 5
#   map :metadata, :string, :string, 6
#   optional :custom_metadata, :bytes, 7
#   optional :data, :bytes, 8
# end
# add_message "event_store.client.persistent_subscriptions.ReadResp.SubscriptionConfirmation" do
#   optional :subscription_id, :string, 1
# end