# frozen_string_literal: true

module EventStoreClient
  module Mapper
    class Default
      def serialize(event)
        Event.new(
          id: event.respond_to?(:id) ? event.id : nil,
          type: (event.respond_to?(:type) ? event.type : nil) || event.class.to_s,
          data: serializer.serialize(event.data),
          metadata: serializer.serialize(event.metadata)
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
          id: event.id,
          type: event.type,
          title: event.title,
          data: data,
          metadata: metadata
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
