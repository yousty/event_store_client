# frozen_string_literal: true

module EventStoreClient
  module Mapper
    class Default
      attr_reader :serializer
      private :serializer

      def initialize(serializer: Serializer::Json)
        @serializer = serializer
      end

      def serialize(event)
        Event.new(
          id: event.respond_to?(:id) ? event.id : nil,
          type: (event.respond_to?(:type) ? event.type : nil) || event.class.to_s,
          data: serializer.serialize(event.data),
          metadata: serializer.serialize(event.metadata)
        )
      end

      def deserialize(event, **)
        metadata = serializer.deserialize(event.metadata)
        data = serializer.deserialize(event.data)

        event_class =
          begin
            Object.const_get(event.type)
          rescue NameError
            EventStoreClient.config.default_event_class
          end
        event_class.new(
          skip_validation: true,
          id: event.id,
          type: event.type,
          title: event.title,
          data: data,
          metadata: metadata,
          stream_revision: event.stream_revision,
          stream_name: event.stream_name
        )
      end
    end
  end
end
