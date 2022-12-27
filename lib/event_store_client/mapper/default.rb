# frozen_string_literal: true

# rubocop:disable Layout/LineLength

module EventStoreClient
  module Mapper
    class Default
      attr_reader :serializer, :config
      private :serializer, :config

      # @param config [EventStoreClient::Config]
      # @param serializer [#serialize, #deserialize]
      def initialize(config:, serializer: Serializer::Json)
        @serializer = serializer
        @config = config
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [EventStoreClient::SerializedEvent]
      def serialize(event)
        Serializer::EventSerializer.call(event, serializer: serializer, config: config)
      end

      # @param event_or_raw_event [EventStoreClient::DeserializedEvent, EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent, EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent]
      # @return event [EventStoreClient::DeserializedEvent]
      def deserialize(event_or_raw_event, **)
        return event_or_raw_event if event_or_raw_event.is_a?(EventStoreClient::DeserializedEvent)

        Serializer::EventDeserializer.call(
          event_or_raw_event, config: config, serializer: serializer
        )
      end
    end
  end
end
# rubocop:enable Layout/LineLength
