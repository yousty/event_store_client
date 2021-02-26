# frozen_string_literal: true

require 'securerandom'
require 'grpc'
require 'event_store_client/adapters/grpc/generated/streams_pb.rb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class LinkTo < Command
          include Configuration

          use_request EventStore::Client::Streams::AppendReq
          use_service EventStore::Client::Streams::Streams::Stub

          def call(stream_name, events, options: {})
            events.each_with_index do |event, index|
              custom_metadata = JSON.generate(
                "type": '$>',
                "created_at": Time.now,
                "encryption": event.metadata['encryption'] || ''
              )

              event_metadata = event.metadata.tap do |h|
                h['type'] = '$>'
                h['content-type'] = 'application/json'
                h.delete('encryption')
              end

              event_id = event.id
              event_id = SecureRandom.uuid if event.id.nil? || event.id.empty?

              payload = [
                request.new(
                  options: {
                    stream_identifier: {
                      streamName: stream_name
                    },
                    any: {}
                  }
                ),
                request.new(
                  proposed_message: {
                    id: {
                      string: event_id
                    },
                    data: event.title,
                    custom_metadata: custom_metadata,
                    metadata: event_metadata
                  }
                )
              ]
              service.append(payload, metadata: metadata)
            end
            Success()
          end
        end
      end
    end
  end
end
