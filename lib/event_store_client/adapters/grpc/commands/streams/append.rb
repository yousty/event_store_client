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
          use_request EventStore::Client::Streams::AppendReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # TODO: Add support to verify the expected version
          def call(stream, events, options: {}) # rubocop:disable Lint/UnusedMethodArgument,Metrics/LineLength
            serialized_events = events.map { |event| config.mapper.serialize(event) }

            serialized_events.each do |event|
              event_metadata = JSON.parse(event.metadata)
              custom_metadata = {
                "type": event.type,
                "created_at": Time.now,
                'content-type': event_metadata['content-type']
              }
              custom_metadata['encryption'] = event_metadata['encryption'] unless event_metadata['encryption'].nil?
              custom_metadata['transaction'] = event_metadata['transaction'] unless event_metadata['transaction'].nil?
              event_metadata = event_metadata.select { |k| ['type', 'content-type', 'created_at'].include?(k) }

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
                    data: event.data.b,
                    custom_metadata: JSON.generate(custom_metadata),
                    metadata: event_metadata
                  }
                )
              ]
              service.append(payload, metadata: metadata)
            end
            Success(events)
          end
        end
      end
    end
  end
end
