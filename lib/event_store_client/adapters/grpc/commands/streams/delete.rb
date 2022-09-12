# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Delete < Command
          use_request EventStore::Client::Streams::DeleteReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#delete_stream}
          def call(stream_name, options:, &blk)
            options = normalize_options(stream_name, options)
            yield options if blk
            Success(
              retry_request { service.delete(request.new(options: options), metadata: metadata) }
            )
          rescue ::GRPC::FailedPrecondition
            Failure(:stream_not_found)
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::TombstoneReq::Options]
          def normalize_options(stream_name, options)
            opts = Options::Streams::WriteOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::DeleteReq::Options.new(opts)
          end
        end
      end
    end
  end
end
