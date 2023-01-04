# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class HardDelete < Command
          use_request EventStore::Client::Streams::TombstoneReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#hard_delete_stream}
          def call(stream_name, options:, &blk)
            options = normalize_options(stream_name, options)
            yield options if blk
            retry_request { service.delete(request.new(options: options), metadata: metadata) }
          rescue ::GRPC::FailedPrecondition => e
            # GRPC::FailedPrecondition may happen for several reasons. For example, stream may not
            # be existing, or :expected_revision option value does not match the current state of
            # the stream. So, re-raise our own error, and pass there the original message - just in
            # case.
            raise StreamDeletionError.new(stream_name, details: e.message)
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::TombstoneReq::Options]
          def normalize_options(stream_name, options)
            opts = Options::Streams::WriteOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::TombstoneReq::Options.new(opts)
          end
        end
      end
    end
  end
end
