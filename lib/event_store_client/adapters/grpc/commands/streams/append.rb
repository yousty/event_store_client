# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Append < Command
          use_request EventStore::Client::Streams::AppendReq
          use_service EventStore::Client::Streams::Streams::Stub

          ALLOWED_EVENT_METADATA = %w[type content-type created_at].freeze

          # @api private
          def call(stream, events, options: {})
            return unless events.any?

            serialized_events = events.map { |event| config.mapper.serialize(event) }

            expected_version = options[:expected_version]

            res = nil
            serialized_events.each_with_index do |event, i|
              expected_version += i if expected_version
              res = append(stream, event, expected_version)
              break if res.failure?
            end

            res
          end

          private

          def append(stream, event, expected_version)
            event_metadata = JSON.parse(event.metadata)

            payload = append_request_payload(
              options(stream, expected_version),
              message(
                data: event.data.b,
                event_metadata: event_metadata.select { |k| ALLOWED_EVENT_METADATA.include?(k) },
                custom_metadata: custom_metadata(event.type, event_metadata)
              )
            )

            begin
              resp = service.append(payload, metadata: metadata)
            rescue StandardError => e
              return Failure(e)
            end

            validate_response(resp)
          end

          def custom_metadata(event_type, event_metadata)
            {
              type: event_type,
              created_at: Time.now,
              encryption: event_metadata['encryption'],
              'content-type': event_metadata['content-type'],
              transaction: event_metadata['transaction']
            }.compact
          end

          def append_request_payload(options, message)
            [
              request.new(
                options: options
              ),
              request.new(
                proposed_message: message
              )
            ]
          end

          def options(stream, expected_version)
            {
              stream_identifier: {
                streamName: stream
              },
              revision: expected_version,
              any: (expected_version ? nil : {})
            }.compact
          end

          def message(data:, event_metadata:, custom_metadata:)
            {
              id: {
                string: SecureRandom.uuid
              },
              data: data,
              custom_metadata: JSON.generate(custom_metadata),
              metadata: event_metadata
            }
          end

          def validate_response(resp)
            return Success(resp) if resp.success

            Failure(
              "current version: #{resp.wrong_expected_version.current_revision} | "\
              "expected: #{resp.wrong_expected_version.expected_revision}"
            )
          end
        end
      end
    end
  end
end
