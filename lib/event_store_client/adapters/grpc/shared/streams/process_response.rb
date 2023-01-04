# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessResponse
          attr_reader :config
          private :config

          # @param config [EventStoreClient::Config]
          def initialize(config:)
            @config = config
          end

          # @api private
          # @param response [EventStore::Client::Streams::ReadResp]
          # @param skip_deserialization [Boolean]
          # @param skip_decryption [Boolean]
          # @return [EventStoreClient::DeserializedEvent, EventStore::Client::Streams::ReadResp, nil]
          # @raise [EventStoreClient::StreamNotFoundError]
          def call(response, skip_deserialization, skip_decryption)
            non_existing_stream = response.stream_not_found&.stream_identifier&.stream_name
            raise StreamNotFoundError, non_existing_stream if non_existing_stream
            return response if skip_deserialization
            return unless response.event&.event

            config.mapper.deserialize(response.event.event, skip_decryption: skip_decryption)
          end
        end
      end
    end
  end
end
