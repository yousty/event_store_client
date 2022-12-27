# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Layout/LineLength

module EventStoreClient
  module Serializer
    class EventDeserializer
      class << self
        # @param raw_event [EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent, EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent]
        # @param config [EventStoreClient::Config]
        # @param serializer [#serialize, #deserialize]
        # @return [EventStoreClient::DeserializedEvent]
        def call(raw_event, config:, serializer: Serializer::Json)
          new(config: config, serializer: serializer).call(raw_event)
        end
      end

      attr_reader :serializer, :config
      private :serializer, :config

      # @param serializer [#serialize, #deserialize]
      # @param config [EventStoreClient::Config]
      def initialize(serializer:, config:)
        @serializer = serializer
        @config = config
      end

      # @param raw_event [EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent, EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent]
      # @return [EventStoreClient::DeserializedEvent]
      def call(raw_event)
        data = serializer.deserialize(normalize_serialized(raw_event.data))
        custom_metadata = serializer.deserialize(normalize_serialized(raw_event.custom_metadata))
        metadata = raw_event.metadata.to_h

        event_class(metadata['type']).new(
          skip_validation: true,
          id: raw_event.id.string,
          title: "#{raw_event.stream_revision}@#{raw_event.stream_identifier.stream_name}",
          type: metadata['type'],
          data: data,
          metadata: metadata,
          custom_metadata: custom_metadata,
          stream_revision: raw_event.stream_revision,
          commit_position: raw_event.commit_position,
          prepare_position: raw_event.prepare_position,
          stream_name: raw_event.stream_identifier.stream_name
        )
      end

      private

      # @param event_type [String]
      # @return [Class<EventStoreClient::DeserializedEvent>]
      def event_class(event_type)
        Object.const_get(event_type)
      rescue NameError, TypeError
        config.logger&.debug(<<~TEXT.strip)
          Unable to resolve class by `#{event_type}' event type. \
          Picking default `#{config.default_event_class}' event class to instantiate the event.
        TEXT
        config.default_event_class
      end

      # @param raw_data [String]
      # @return [String]
      def normalize_serialized(raw_data)
        return serializer.serialize({}) if raw_data.empty?

        raw_data
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Layout/LineLength
