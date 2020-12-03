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

            include Configuration

            # TODO: This is WIP, not working at the moment.
            #
            def call(stream, events, expected_version)
              serialized_events = events.map { |event| config.mapper.serialize(event) }

              payload = serialized_events.map do |event|
                [
                  request.new(
                    options: {
                      stream_identifier: {
                        streamName: stream
                      },
                      any: {}
                    }
                  ),
                  request.new(
                    proposed_message: {
                      id: {
                        string: SecureRandom.uuid
                      },
                      data: event.data,
                      custom_metadata: '{}',
                      metadata: JSON.parse(event.metadata)
                    }
                  )
                ]
              end.flatten
              service.append(payload)
              Success()
            end
          end
        end
      end
    end
  end
end
