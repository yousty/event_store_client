# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessResponses
          include Dry::Monads[:result]

          # @api private
          # @param responses [Array<EventStore::Client::Streams::ReadResp>]
          # @param skip_deserialization [Boolean]
          # @param skip_decryption [Boolean]
          # @return [Dry::Monads::Success, Dry::Monads::Failure]
          def call(responses, skip_deserialization, skip_decryption)
            return Failure(:stream_not_found) if responses.first&.stream_not_found
            return Success(responses) if skip_deserialization

            events =
              responses.map do |read_resp|
                # It could be <EventStore::Client::Streams::ReadResp: last_stream_position: 39> for
                # example. See generated files for more info
                next unless read_resp.event

                EventDeserializer.new.call(read_resp.event.event, skip_decryption)
              end
            Success(events.compact)
          end
        end
      end
    end
  end
end
