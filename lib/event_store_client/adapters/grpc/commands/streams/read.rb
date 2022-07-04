# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Read < Command
          include Configuration

          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#read}
          def call(stream_name, options: {}, skip_deserialization: false, skip_decryption: false)
            options = normalize_options(stream_name, options)
            yield options if block_given?
            result =
              retry_request { service.read(request.new(options: options), metadata: metadata).to_a }
            EventStoreClient::GRPC::Shared::Streams::ProcessReadResponse.new.call(
              result,
              skip_decryption,
              skip_deserialization
            )
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::ReadReq::Options]
          def normalize_options(stream_name, options)
            options = Options::Streams::ReadOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::ReadReq::Options.new(options)
          end
        end
      end
    end
  end
end
