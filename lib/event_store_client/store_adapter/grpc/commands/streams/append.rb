# frozen_string_literal: true

require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Streams
          class Append < Command
            use_request EventStore::Client::Streams::AppendReq
            use_service EventStore::Client::Streams::Streams::Stub

            # TODO: This is WIP, not working at the moment.
            #
            def call(name, events, expected_version)
              serialized_events = events.map { |event| mapper.serialize(event) }

              events = [events].map do |event|
                request.new(
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
              service.append(events)
              Success()
            end
          end
        end
      end
    end
  end
end
