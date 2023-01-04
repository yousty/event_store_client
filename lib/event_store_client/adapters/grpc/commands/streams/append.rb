# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Append < Command
          use_request EventStore::Client::Streams::AppendReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#append_to_stream}
          def call(stream_name, event, options:, &blk)
            payload =
              [
                request.new(options: options(stream_name, options)),
                request.new(proposed_message: proposed_message(event))
              ]
            yield(*payload) if blk
            response = retry_request(skip_retry: config.eventstore_url.throw_on_append_failure) do
              service.append(payload, metadata: metadata)
            end
            validate_response(response, caused_by: event)
          end

          private

          # @param event [EventStoreClient::DeserializedEvent]
          # @return [EventStore::Client::Streams::AppendReq::ProposedMessage]
          def proposed_message(event)
            serialized_event = config.mapper.serialize(event)
            EventStore::Client::Streams::AppendReq::ProposedMessage.new(serialized_event.to_grpc)
          end

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::AppendReq::Options]
          def options(stream_name, options)
            opts = Options::Streams::WriteOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::AppendReq::Options.new(opts)
          end

          # @param resp [EventStore::Client::Streams::AppendResp]
          # @param caused_by [EventStoreClient::DeserializedEvent]
          # @return [EventStore::Client::Streams::AppendResp]
          # @raise [EventStoreClient::WrongExpectedVersionError]
          def validate_response(resp, caused_by:)
            return resp if resp.success

            error = WrongExpectedVersionError.new(
              resp.wrong_expected_version,
              caused_by: caused_by
            )
            raise error
          end
        end
      end
    end
  end
end
