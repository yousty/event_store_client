# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Read < Command
          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#read}
          def call(stream_name, options:, skip_deserialization:, skip_decryption:)
            options = normalize_options(stream_name, options)
            yield options if block_given?
            result =
              retry_request { service.read(request.new(options: options), metadata: metadata).to_a }
            EventStoreClient::GRPC::Shared::Streams::ProcessResponses.new(config: config).call(
              result,
              skip_deserialization,
              skip_decryption
            )
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::ReadReq::Options]
          def normalize_options(stream_name, options)
            options =
              Options::Streams::ReadOptions.
                new(stream_name, options, config: config).
                request_options
            EventStore::Client::Streams::ReadReq::Options.new(options)
          end
        end
      end
    end
  end
end
