# frozen_string_literal: true

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
            events.each do |event|
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
                      string: event.id
                    },
                    data: event.title,
                    custom_metadata: JSON.generate(
                      "type": '$>',
                      "content-type": 'application/vnd.eventstore.events+json',
                      "created_at": Time.now
                    ),
                    metadata: event.metadata.tap { |h| h['type'] = '$>' }
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
