# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/streams_pb.rb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Append < Command
          include Configuration

          use_request EventStore::Client::Streams::AppendReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # TODO: Add support to verify the expected version
          def call(stream, events, options: {}) # rubocop:disable Lint/UnusedMethodArgument,Metrics/LineLength
            serialized_events = events.map { |event| config.mapper.serialize(event) }

            serialized_events.each do |event|
              payload = [
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
                    custom_metadata: JSON.generate(
                      "type": event.type,
                      "content-type": 'application/vnd.eventstore.events+json',
                      "created_at": Time.now
                    ),
                    metadata: JSON.parse(event.metadata)
                  }
                )
              ]
              service.append(payload)
            end
            Success()
          end
        end
      end
    end
  end
end
