# frozen_string_literal: true

module EventStoreClient
  module Mapper
    class Default
      def serialize(event)
        Event.new(
          metadata: serializer.serialize(event.metadata),
          data: serializer.serialize(event.data),
          type: event.class.to_s
        )
      end

      def deserialize(event)
        metadata = serializer.deserialize(event.metadata)
        data = serializer.deserialize(event.data)

        event_class = event.type.safe_constantize
        if event_class
          event_class.new(
            metadata: metadata,
            data: data
          )
        else
          EventStoreClient::DeserializedEvent.new(
            metadata: metadata,
            data: data,
            type: event.type
          )
        end
      end

      private

      attr_reader :serializer

      def initialize(serializer: Serializer::Json)
        @serializer = serializer
      end
    end
  end
end
