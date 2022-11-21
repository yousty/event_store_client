# frozen_string_literal: true

# rubocop:disable Layout/LineLength

module EventStoreClient
  module Mapper
    class Default
      attr_reader :serializer
      private :serializer

      # @param serializer [#serialize, #deserialize]
      def initialize(serializer: Serializer::Json)
        @serializer = serializer
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [EventStoreClient::SerializedEvent]
      def serialize(event)
        Serializer::EventSerializer.call(event, serializer: serializer)
      end

      # @param event_or_raw_event [EventStoreClient::DeserializedEvent, EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent, EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent]
      # @return event [EventStoreClient::DeserializedEvent]
      def deserialize(event_or_raw_event, **)
        return event_or_raw_event if event_or_raw_event.is_a?(EventStoreClient::DeserializedEvent)

        Serializer::EventDeserializer.call(event_or_raw_event, serializer: serializer)
      end
    end
  end
end
# rubocop:enable Layout/LineLength
