# frozen_string_literal: true

require 'grpc'
require 'fast_jsonparser'
require 'event_store_client/adapters/grpc/generated/streams_pb.rb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb.rb'

require 'event_store_client/configuration'
require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Read < Command
          include Configuration

          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          StreamNotFound = Class.new(StandardError)

          def call(name, options: {})
            direction =
              EventStoreClient::ReadDirection.new(options[:direction] || 'forwards').to_sym
            opts = {
              stream: {
                stream_identifier: {
                  streamName: name
                }
              },
              read_direction: direction,
              resolve_links: options[:resolve_links] || true,
              count: options[:count] || config.per_page,
              uuid_option: {
                string: {}
              },
              no_filter: {}
            }
            options[:start] ||= 0
            if options[:start].zero?
              opts[:stream][:start] = {}
            else
              opts[:stream][:revision] = options[:start]
            end

            skip_decryption = options[:skip_decryption] || false
            events =
              if options[:skip_deserialization]
                read_stream_raw(opts)
              else
                read_stream(opts, skip_decryption)
              end
            Success(events)
          rescue StreamNotFound
            Failure(:not_found)
          end

          private

          def read_stream(options, skip_decryption)
            retries ||= 0
            service.read(request.new(options: options), metadata: metadata).map do |res|
              raise StreamNotFound if res.stream_not_found
              deserialize_event(res.event.event, skip_decryption: skip_decryption)
            end
          rescue ::GRPC::Unavailable
            sleep config.grpc_unavailable_retry_sleep
            retry if (retries += 1) <= config.grpc_unavailable_retry_count
            raise GRPCUnavailableRetryFailed
          end

          def read_stream_raw(options)
            retries ||= 0
            service.read(request.new(options: options), metadata: metadata).map do |res|
              raise StreamNotFound if res.stream_not_found
              res.event.event
            end
          rescue ::GRPC::Unavailable
            sleep config.grpc_unavailable_retry_sleep
            retry if (retries += 1) <= config.grpc_unavailable_retry_count
            raise GRPCUnavailableRetryFailed
          end

          def deserialize_event(entry, skip_decryption: false)
            data = (entry.data.nil? || entry.data.empty?) ? '{}' : entry.data

            metadata =
              FastJsonparser.parse(entry.custom_metadata || '{}').merge(
                entry.metadata.to_h || {}
              ).to_json

            event = EventStoreClient::Event.new(
              id: entry.id.string,
              title: "#{entry.stream_revision}@#{entry.stream_identifier.streamName}",
              type: entry.metadata['type'],
              data: data,
              metadata: metadata
            )

            config.mapper.deserialize(event, skip_decryption: skip_decryption)
          end
        end
      end
    end
  end
end
