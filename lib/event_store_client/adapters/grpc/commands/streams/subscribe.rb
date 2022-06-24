# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

require 'event_store_client/configuration'
require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Subscribe < Command
          include Configuration

          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          StreamNotFound = Class.new(StandardError)

          def call(options = {})
            opts = options_with_defaults(options)

            service.read(request.new(options: opts), metadata: metadata).map do |res|
              raise StreamNotFound if res.stream_not_found

              yield prepared_response(res) if block_given?
            end
          rescue StreamNotFound
            Failure(:not_found)
          end

          private

          def prepared_response(res)
            if res.event
              event = res.event.event
              [position(event), deserialize_event(event)] rescue event
            elsif res.checkpoint
              [position(res.checkpoint), nil]
            elsif res.confirmation
              res.confirmation
            end
          end

          def position(event_or_checkpoint)
            {
              prepare_position: event_or_checkpoint.prepare_position,
              commit_position: event_or_checkpoint.commit_position
            }
          end

          def read_direction(direction)
            EventStoreClient::ReadDirection.new(direction || 'forwards').to_sym
          end

          def options_with_defaults(options)
            options[:without_system_events] = true unless options[:without_system_events] == false
            opts = {
              subscription: {},
              read_direction: read_direction(options[:direction]),
              resolve_links: options[:resolve_links] || true,
              uuid_option: {
                string: {}
              }
            }
            if options[:stream]
              opts[:stream] = {
                stream_identifier: {
                  stream_name: stream
                }
              }
            else
              opts[:all] = options[:all] || default_all_options
            end
            if options[:filter]
              opts[:filter] = options[:filter]
            elsif options[:without_system_events]
              opts[:filter] = {
                event_type: { regex: '^[^$].*' },
                max: 32,
                checkpointIntervalMultiplier: 1000
              }
            else
              opts[:no_filter] = {}
            end

            options[:start] ||= 0

            return opts unless options[:stream]

            if options[:start].zero?
              opts[:stream][:start] = {}
            else
              opts[:stream][:revision] = options[:start]
            end
            opts
          end

          def default_all_options
            {
              position: {
                commit_position: 0,
                prepare_position: 0
              }
            }
          end

          def deserialize_event(entry)
            data = (entry.data.nil? || entry.data.empty?) ? '{}' : entry.data

            metadata =
              JSON.parse(entry.custom_metadata || '{}').merge(
                entry.metadata.to_h || {}
              ).to_json

            event = EventStoreClient::Event.new(
              id: entry.id.string,
              title: "#{entry.stream_revision}@#{entry.stream_identifier.stream_name}",
              type: entry.metadata['type'],
              data: data,
              metadata: metadata
            )

            config.mapper.deserialize(event)
          end
        end
      end
    end
  end
end
