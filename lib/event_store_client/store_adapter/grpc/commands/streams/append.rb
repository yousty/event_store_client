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
          class Append
            include Dry::Monads[:result]
            include Configuration

            # TODO: This is WIP, not working at the moment.
            #
            def call(name, events, expected_version)
              serialized_events = events.map { |event| mapper.serialize(event) }

              client = EventStore::Client::Streams::Streams::Stub.new(
                uri.to_s, :this_channel_is_insecure
              )

              events = [events].map do |event|
                ::EventStore::Client::Streams::AppendReq.new(
                  options: {
                    stream_identifier: {
                      streamName: 'grpc'
                    },
                    any: {}
                  },
                  proposed_message: {
                    id: {
                      string: SecureRandom.uuid
                    },
                    data: '', # JSON.generate(event.data),
                    custom_metadata: '',
                    metadata: { 'type' => 'UserRegistered' } #event.metadata.merge('type' => event.type)
                  }
                )
              end
              client.append(events)
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
