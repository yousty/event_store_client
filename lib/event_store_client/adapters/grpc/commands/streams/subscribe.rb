# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/streams_pb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb'

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class Subscribe < Command
          use_request EventStore::Client::Streams::ReadReq
          use_service EventStore::Client::Streams::Streams::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#read}
          def call(stream_name, handler:, options:, skip_deserialization:, skip_decryption:)
            options = normalize_options(stream_name, options)
            yield options if block_given?

            callback = proc do |response|
              result = Shared::Streams::ProcessResponse.new.call(
                response,
                skip_deserialization,
                skip_decryption
              )

              handler.call(result) if result
            end
            Success(service.read(request.new(options: options), metadata: metadata, &callback))
          end

          private

          # @param stream_name [String]
          # @param options [Hash]
          # @return [EventStore::Client::Streams::ReadReq::Options]
          def normalize_options(stream_name, options)
            options = Options::Streams::ReadOptions.new(stream_name, options).request_options
            EventStore::Client::Streams::ReadReq::Options.new(options).tap do |opts|
              opts.subscription =
                EventStore::Client::Streams::ReadReq::Options::SubscriptionOptions.new
            end
          end
        end
      end
    end
  end
end
