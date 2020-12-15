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
              opts =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  group_name: group,
                  uuid_option: {
                    structured: {}
                  }
                }

              requests = [request.new(options: opts)] # please notice that it's an array. Should be?
              res = service.read(requests).each do |res|
                # res contains only: "Subscription Confirmation", here, no events at all.
              end
              Success()
            end

            private
          end
        end
      end
    end
  end
end
