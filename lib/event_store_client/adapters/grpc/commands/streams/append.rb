# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

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

            revision = Options::Streams::RevisionOption.new(options[:expected_revision])

            res = nil
            serialized_events.each_with_index do |event, i|
              revision.increment! if revision.number? && i > 0
              res = append(stream, event, revision)
              break if res.failure?
            end

            res
          end

          private

          # @param stream [String]
          # @param event [EventStoreClient::Event, EventStoreClient::DeserializedEvent]
          # @param revision [EventStoreClient::GRPC::Options::Streams::RevisionOption]
          # @return [Dry::Monads]
          def append(stream, event, revision)
            event_metadata = JSON.parse(event.metadata)

            payload = append_request_payload(
              options(stream, revision),
              message(
                id: event.id,
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

          # @param stream [String]
          # @param revision [EventStoreClient::GRPC::Options::Streams::RevisionOption]
          # @return [EventStore::Client::Streams::AppendReq::Options]
          def options(stream, revision)
            opts =
              {
                stream_identifier: {
                  stream_name: stream
                }
              }
            opts.merge!(revision.request_options) if revision.request_options
            EventStore::Client::Streams::AppendReq::Options.new(opts)
          end

          # @return [EventStore::Client::Streams::AppendReq::ProposedMessage]
          def message(id: nil, data:, event_metadata:, custom_metadata:)
            opts =
              {
                id: {
                  string: id || SecureRandom.uuid
                },
                data: data,
                custom_metadata: JSON.generate(custom_metadata),
                metadata: event_metadata
              }
            EventStore::Client::Streams::AppendReq::ProposedMessage.new(opts)
          end

          def validate_response(resp)
            return Success(resp) if resp.success

            Failure(resp.wrong_expected_version)
          end
        end
      end
    end
  end
end
