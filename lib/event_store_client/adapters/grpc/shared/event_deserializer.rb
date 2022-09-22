# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module EventStoreClient
  module GRPC
    module Shared
      class EventDeserializer
        include Configuration

        # @param raw_event [
        #   Array<EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent>,
        #   Array<EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent>
        # ]
        # @param skip_decryption [Boolean]
        # @return [EventStoreClient::DeserializedEvent]
        def call(raw_event, skip_decryption: false)
          data = normalize_serialized(raw_event.data)
          custom_metadata = normalize_serialized(raw_event.custom_metadata)

          metadata =
            JSON.parse(custom_metadata).merge(raw_event.metadata.to_h).to_json

          event = EventStoreClient::Event.new(
            id: raw_event.id.string,
            title: "#{raw_event.stream_revision}@#{raw_event.stream_identifier.stream_name}",
            type: raw_event.metadata['type'],
            data: data,
            metadata: metadata,
            stream_revision: raw_event.stream_revision,
            commit_position: raw_event.commit_position,
            prepare_position: raw_event.prepare_position,
            stream_name: raw_event.stream_identifier.stream_name
          )

          config.mapper.deserialize(event, skip_decryption: skip_decryption)
        end

        private

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
# rubocop:enable Metrics/AbcSize
