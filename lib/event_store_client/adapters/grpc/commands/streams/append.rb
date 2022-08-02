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
          # @see {EventStoreClient::GRPC::Client#append_to_stream}
          def call(stream_name, event, options:, &blk)
            serialize_event = config.mapper.serialize(event)
            payload =
              [
                request.new(options: options(stream_name, options)),
                request.new(proposed_message: proposed_message(serialize_event))
              ]
            yield *payload if block_given?
            response = retry_request(skip_retry: config.eventstore_url.throw_on_append_failure) do
              service.append(payload, metadata: metadata)
            end
            validate_response(response)
          rescue ::GRPC::Unavailable => e
            Failure(e)
          end

          private

          # @param serialized_event [EventStoreClient::Event]
          # @return [EventStore::Client::Streams::AppendReq::ProposedMessage]
          def proposed_message(serialized_event)
            event_metadata = JSON.parse(serialized_event.metadata)
            custom_metadata = custom_metadata(serialized_event.type, event_metadata)
            opts =
              {
                id: {
                  string: serialized_event.id
                },
                data: serialized_event.data.b,
                custom_metadata: custom_metadata.to_json,
                metadata: event_metadata.slice(*ALLOWED_EVENT_METADATA)
              }
            EventStore::Client::Streams::AppendReq::ProposedMessage.new(opts)
          end

          # @param event_type [String]
          # @param event_metadata [Hash]
          # @return [Hash]
          def custom_metadata(event_type, event_metadata)
            {
              type: event_type,
              created_at: Time.now,
              encryption: event_metadata['encryption'],
              'content-type': event_metadata['content-type'],
              transaction: event_metadata['transaction']
            }.compact
          end

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::AppendReq::Options]
          def options(stream_name, options)
            opts = Options::Streams::WriteOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::AppendReq::Options.new(opts)
          end

          # @param resp [EventStore::Client::Streams::AppendResp]
          # @return [Dry::Monads::Success, Dry::Monads::Failure]
          def validate_response(resp)
            return Success(resp) if resp.success

            Failure(resp.wrong_expected_version)
          end
        end
      end
    end
  end
end
