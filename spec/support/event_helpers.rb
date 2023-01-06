# frozen_string_literal: true

module EventHelpers
  # @param stream_name [String]
  # @param event [EventStoreClient::DeserializedEvent]
  # @return [EventStoreClient::DeserializedEvent]
  def append_and_reload(stream_name, event, **options)
    EventStoreClient.client.append_to_stream(stream_name, event)
    EventStoreClient.client.read(
      '$all',
      **options.merge(
        options: {
          direction: 'Backwards',
          from_position: :end,
          max_count: 1,
          filter: { stream_identifier: { prefix: [stream_name] } }
        }
      )
    ).first
  end

  # @param stream_name [String]
  def safe_read(stream_name)
    EventStoreClient.client.read(
      '$all',
      options: {
        max_count: 1_000,
        filter: { stream_identifier: { prefix: [stream_name] } }
      }
    )
  rescue EventStoreClient::StreamNotFoundError
  end
end
