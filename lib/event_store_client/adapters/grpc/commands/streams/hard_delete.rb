# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class HardDelete < Command
          use_request EventStore::Client::Streams::TombstoneReq
          use_service EventStore::Client::Streams::Streams::Stub


          # @api private
          # @see {EventStoreClient::GRPC::Client#delete_stream}
          def call(stream_name, options: {}, &blk)
            options = normalize_options(stream_name, options)
            yield options if block_given?
            Success(service.delete(request.new(options: options), metadata: metadata))
          rescue ::GRPC::FailedPrecondition
            Failure(:stream_not_found)
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::TombstoneReq::Options]
          def normalize_options(stream_name, options)
            opts = { stream_identifier: { stream_name: stream_name } }
            opts.merge!(
              Options::Streams::RevisionOption.new(options[:expected_revision]).request_options
            )
            EventStore::Client::Streams::TombstoneReq::Options.new(opts)
          end
        end
      end
    end
  end
end
