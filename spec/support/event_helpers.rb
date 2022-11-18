# frozen_string_literal: true

module EventHelpers
  def append_and_reload(stream_name, event, **options)
    EventStoreClient.client.append_to_stream(stream_name, event)
    EventStoreClient.client.read_paginated(stream_name, **options).flat_map(&:success).last
  end
end
