# frozen_string_literal: true

module EventStoreClient
  module Adapter
    class InMemory
      attr_reader :event_store

      def append_to_stream(stream_name, events, expected_version: nil)
        event_store[stream_name] = [] unless event_store.key?(stream_name)

        [events].flatten.each do |event|
          event_store[stream_name].unshift(
            'eventId' => event.id,
            'data' => event.data,
            'eventType' => event.type,
            'metadata' => event.metadata,
            'positionEventNumber' => event_store[stream_name].length
          )
        end
      end

      def delete_stream(stream_name, hard_delete: false)
        event_store.delete(stream_name)
      end

      def read_stream_backward(stream_name, start: 0, count: per_page)
        return [] unless event_store.key?(stream_name)

        start = start == 0 ? event_store[stream_name].length - 1 : start
        last_index = start - count
        entries = event_store[stream_name].select do |event|
          event['positionEventNumber'] > last_index &&
            event['positionEventNumber'] <= start
        end
        {
          'entries' => entries,
          'links' => links(stream_name, last_index, 'next', entries, count)
        }
      end

      def read_stream_forward(stream_name, start: 0, count: per_page)
        return [] unless event_store.key?(stream_name)

        last_index = start + count
        entries = event_store[stream_name].reverse.select do |event|
          event['positionEventNumber'] < last_index &&
            event['positionEventNumber'] >= start
        end
        {
          'entries' => entries,
          'links' => links(stream_name, last_index, 'previous', entries, count)
        }
      end

      private

      attr_reader :endpoint, :per_page

      def initialize(host:, port:, per_page: 20)
        @endpoint = Endpoint.new(host: host, port: port)
        @per_page = per_page
        @event_store = {}
      end

      def links(stream_name, batch_size, direction, entries, count)
        if entries.empty? || batch_size < 0
          []
        else
          [{
                'uri' => "http://#{endpoint.url}/streams/#{stream_name}/#{batch_size}/#{direction}/#{count}",
                'relation' => direction
            }]
        end
      end
    end
  end
end
