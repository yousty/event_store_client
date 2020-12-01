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
          class Read
            include Dry::Monads[:result]
            include Configuration

            def call(name, options: {})
              opts = {
                stream: {
                  stream_identifier: {
                    streamName: name
                  }
                },
                read_direction: EventStoreClient::ReadDirection.new(options[:direction]).to_sym,
                resolve_links: options[:resolve_links],
                count: options[:count] || config.per_page,
                uuid_option: {
                  string: {}
                },
                no_filter: {}
              }
              if options[:start]&.zero?
                opts[:stream][:start] = {}
              else
                opts[:stream][:revision] = options[:start]
              end

              client = EventStore::Client::Streams::Streams::Stub.new(
                uri.to_s, :this_channel_is_insecure
              )

              request = ::EventStore::Client::Streams::ReadReq.new(options: opts)
              client.read(request).map do |res|
                raise StreamNotFound if res.stream_not_found

                deserialize_event(res.event.event)
              end
            rescue StreamNotFound
              Failure(:not_found)
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
