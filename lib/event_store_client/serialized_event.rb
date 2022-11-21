# frozen_string_literal: true

module EventStoreClient
  class SerializedEvent
    include Extensions::OptionsExtension

    option(:id)
    option(:data)
    option(:custom_metadata)
    option(:metadata)
    option(:serializer)

    # Constructs a hash that can be passed directly in the proposed_message attribute of the append
    # request, or it can be used to instantiate the raw EventStore event.
    # Example:
    #   ```ruby
    #   serialized_event = EventStoreClient::SerializedEvent.new(
    #     id: 'some id',
    #     data: { foo: :bar },
    #     custom_metadata: { bar: :baz },
    #     metadata: { baz: :foo },
    #     serializer: EventStoreClient::Serializer::Json
    #   )
    #   # Compute proposed_message
    #   EventStore::Client::Streams::AppendReq::ProposedMessage.new(
    #     serialized_event.to_grpc
    #   )
    #   # Compute raw event
    #   EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent.new(
    #     serialized_event.to_grpc
    #   )
    #   ```
    # @return [Hash]
    def to_grpc
      {
        id: { string: id },
        data: serializer.serialize(data),
        custom_metadata: serializer.serialize(custom_metadata),
        metadata: metadata
      }
    end
  end
end
