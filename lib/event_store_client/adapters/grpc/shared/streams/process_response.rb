# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessResponse
          include Dry::Monads[:result]
          include Configuration

          # @api private
          # @param response [EventStore::Client::Streams::ReadResp]
          # @param skip_deserialization [Boolean]
          # @param skip_decryption [Boolean]
          # @return [Dry::Monads::Success, Dry::Monads::Failure, nil]
          def call(response, skip_deserialization, skip_decryption)
            return Failure(:stream_not_found) if response.stream_not_found
            return Success(response) if skip_deserialization
            return unless response.event&.event

            Success(
              config.mapper.deserialize(response.event.event, skip_decryption: skip_decryption)
            )
          end
        end
      end
    end
  end
end
