# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/persistent_pb.rb'
require 'event_store_client/adapters/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/settings_schema'
require 'irb'
module EventStoreClient
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
            count = options[:count].to_i
            opts =
              {
                stream_identifier: {
                  streamName: stream
                },
                buffer_size: count,
                group_name: group,
                uuid_option: {
                  structured: {}
                }
              }

            requests = [request.new(options: opts)] # please notice that it's an array. Should be?

            skip_decryption = options[:skip_decryption] || false
            service.read(requests, metadata: metadata).each do |res|
              next if res.subscription_confirmation
              yield deserialize_event(res.event.event, skip_decryption: skip_decryption) if block_given?
            end
            Success()
          end

          private

          def deserialize_event(entry, skip_decryption: false)
            id = entry.id.string
            id = SecureRandom.uuid if id.nil? || id.empty?

            data = (entry.data.nil? || entry.data.empty?) ? '{}' : entry.data

            metadata =
              JSON.parse(entry.custom_metadata || '{}').merge(
                entry.metadata.to_h || {}
              ).to_json

            config.mapper.deserialize(
              EventStoreClient::Event.new(
                id: id,
                title: "#{entry.stream_revision}@#{entry.stream_identifier.streamName}",
                type: entry.metadata['type'],
                data: data,
                metadata: metadata
              ),
              skip_decryption: skip_decryption
            )
          end
        end
      end
    end
  end
end
