# frozen_string_literal: true

require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/settings_schema'
require 'irb'
module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module PersistentSubscriptions
          class Read < Command
            include Configuration

            use_request EventStore::Client::PersistentSubscriptions::ReadReq
            use_service EventStore::Client::PersistentSubscriptions::PersistentSubscriptions::Stub

            # Read given persistent subscription
            # @param [String] name of the stream to subscribe
            # @param [String] name of the subscription group
            # @param [Hash] options - additional settings to be set on subscription.
            #   Refer to SettingsSchema for detailed attributes allowed
            # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure]
            #
            def call(stream, group, options: {}, &block)
              opts =
                {
                  stream_identifier: {
                    streamName: stream
                  },
                  buffer_size: 2,
                  group_name: group,
                  uuid_option: {
                    structured: {}
                  }
                }

              requests = [request.new(options: opts)] # please notice that it's an array. Should be?
              count = 0
              event = event

              ids = []
              service.read(requests).each do |res|
                next if res.subscription_confirmation
                block.call(deserialize_event(res.event.event)) if block_given?
              end
              Success()
            end

            private

            def deserialize_event(entry)
              event = EventStoreClient::Event.new(
                id: entry.id.string,
                title: "#{entry.stream_revision}@#{entry.stream_identifier.streamName}",
                type: entry.metadata['type'],
                data: entry.data || '{}',
                metadata: (entry.metadata.to_h || {}).to_json
              )

              config.mapper.deserialize(event)
            end
          end
        end
      end
    end
  end
end
