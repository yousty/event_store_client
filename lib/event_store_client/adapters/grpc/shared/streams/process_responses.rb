# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessResponses
          attr_reader :config
          private :config

          # @param config [EventStoreClient::Config]
          def initialize(config:)
            @config = config
          end

          # @api private
          # @param responses [Array<EventStore::Client::Streams::ReadResp>]
          # @param skip_deserialization [Boolean]
          # @param skip_decryption [Boolean]
          # @return [Array<EventStoreClient::DeserializedEvent>, Array<EventStore::Client::Streams::ReadResp>]
          # @raise [EventStoreClient::StreamNotFoundError]
          def call(responses, skip_deserialization, skip_decryption)
            non_existing_stream = responses.first&.stream_not_found&.stream_identifier&.stream_name
            raise StreamNotFoundError, non_existing_stream if non_existing_stream
            return responses if skip_deserialization

            responses.map do |response|
              # It could be <EventStore::Client::Streams::ReadResp: last_stream_position: 39> for
              # example. Such responses should be skipped. See generated files for more info.
              next unless response.event&.event

              config.mapper.deserialize(response.event.event, skip_decryption: skip_decryption)
            end.compact
          end
        end
      end
    end
  end
end
