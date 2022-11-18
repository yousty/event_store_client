# frozen_string_literal: true

module EventStoreClient
  module Serializer
    class EventSerializer
      ALLOWED_EVENT_METADATA = %w[type content-type created_at].freeze

      class << self
        # @param event [EventStoreClient::DeserializedEvent]
        # @param serializer [#serialize, #deserialize]
        # @return [EventStoreClient::SerializedEvent]
        def call(event, serializer: Serializer::Json)
          new(serializer: serializer).call(event)
        end
      end

      attr_reader :serializer
      private :serializer

      # @param serializer [#serialize, #deserialize]
      def initialize(serializer:)
        @serializer = serializer
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [EventStoreClient::SerializedEvent]
      def call(event)
        event_metadata = metadata(event)
        event_custom_metadata = custom_metadata(event, event_metadata)
        SerializedEvent.new(
          id: event.id || SecureRandom.uuid,
          data: data(event),
          custom_metadata: event_custom_metadata,
          metadata: event_metadata.slice(*ALLOWED_EVENT_METADATA),
          serializer: serializer
        )
      end

      private

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash]
      def metadata(event)
        metadata = serializer.deserialize(serializer.serialize(event.metadata))
        metadata['created_at'] ||= Time.now.utc.to_s
        metadata
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @param metadata [Hash]
      # @return [Hash]
      def custom_metadata(event, metadata)
        metadata.
          slice('created_at', 'encryption', 'content-type', 'transaction').
          merge('type' => event.type.to_s)
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash, String]
      def data(event)
        # Link events are special events. They contain special string value which shouldn't be
        # serialized.
        return event.data if event.link?

        serializer.deserialize(serializer.serialize(event.data))
      end
    end
  end
end
