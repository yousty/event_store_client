# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessResponses
          include Dry::Monads[:result]

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
          # @return [Dry::Monads::Success, Dry::Monads::Failure]
          def call(responses, skip_deserialization, skip_decryption)
            return Failure(:stream_not_found) if responses.first&.stream_not_found
            return Success(responses) if skip_deserialization

            events =
              responses.map do |response|
                # It could be <EventStore::Client::Streams::ReadResp: last_stream_position: 39> for
                # example. Such responses should be skipped. See generated files for more info.
                next unless response.event&.event

                config.mapper.deserialize(response.event.event, skip_decryption: skip_decryption)
              end
            Success(events.compact)
          end
        end
      end
    end
  end
end
