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

        event_class =
          begin
            Object.const_get(event.type)
          rescue NameError
            EventStoreClient::DeserializedEvent
          end

        event_class.new(
          metadata: metadata,
          data: data,
          type: event.type
        )
      end

      private

      attr_reader :serializer

      def initialize(serializer: Serializer::Json)
        @serializer = serializer
      end
    end
  end
end
