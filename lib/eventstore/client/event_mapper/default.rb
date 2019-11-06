# frozen_string_literal: true

module EventStore
  module Client
    module EventMapper
      class Default
        def serialize(event)
          Event.new(
            event_id: event.id,
            metadata: event.metadata,
            data: serializer.serialize(event.data),
            event_type: domain_event.class.to_s
          )
        end

        def deserialize(event)
          metadata = serializer.deserialize(event.metadata)
          data = serializer.deserialize(event.data)

          Object.const_get(record.type).new(
            id: record.id,
            metadata: metadata,
            data: data
          )
        end

        private

        def initialize(serializer: EventStore::Client::Serializer::Json)
          @serializer = serializer
        end
      end
    end
  end
end
