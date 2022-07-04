# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Shared
      module Streams
        class ProcessReadResponse
          include Dry::Monads[:result]
          include Configuration

          # @api private
          # @param raw_events [Array<EventStore::Client::Streams::ReadResp>]
          # @param skip_decryption [Boolean]
          # @param skip_deserialization [Boolean]
          # @return [Dry::Monads::Success, Dry::Monads::Failure]
          def call(raw_events, skip_decryption, skip_deserialization)
            return Failure(:stream_not_found) if raw_events.first&.stream_not_found
            return Success(raw_events) if skip_deserialization

            events =
              raw_events.map do |read_resp|
                # It could be <EventStore::Client::Streams::ReadResp: last_stream_position: 39> for
                # example. See generated files for more info
                next unless read_resp.event

                deserialize_event(read_resp.event.event, skip_decryption)
              end
            Success(events.compact)
          end

          private

          # @param raw_event [Array<EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent>]
          # @param skip_decryption [Boolean]
          # @return [EventStoreClient::DeserializedEvent]
          def deserialize_event(raw_event, skip_decryption = false)
            data = normalize_serialized(raw_event.data)
            custom_metadata = normalize_serialized(raw_event.custom_metadata)

            metadata =
              JSON.parse(custom_metadata).merge(
                raw_event.metadata.to_h || {}
              ).to_json

            event = EventStoreClient::Event.new(
              id: raw_event.id.string,
              title: "#{raw_event.stream_revision}@#{raw_event.stream_identifier.stream_name}",
              type: raw_event.metadata['type'],
              data: data,
              metadata: metadata,
              stream_revision: raw_event.stream_revision,
              stream_name: raw_event.stream_identifier.stream_name
            )

            config.mapper.deserialize(event, skip_decryption: skip_decryption)
          end

          # @param raw_data [String, nil]
          # @return [String]
          def normalize_serialized(raw_data)
            return {}.to_json if raw_data.nil? || raw_data.empty?

            raw_data
          end
        end
      end
    end
  end
end
