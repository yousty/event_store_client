# frozen_string_literal: true

module EventStoreClient
  module StoreAdapter
    class InMemory
      Response = Struct.new(:body, :status) do
        def success?
          status == 200
        end
      end

      attr_reader :event_store

      def append_to_stream(stream_name, events, expected_version: nil) # rubocop:disable Lint/UnusedMethodArgument,Metrics/LineLength
        event_store[stream_name] = [] unless event_store.key?(stream_name)

        [events].flatten.each do |event|
          event_store[stream_name].unshift(
            'eventId' => event.id,
            'data' => event.data,
            'eventType' => event.type,
            'metaData' => event.metadata,
            'positionEventNumber' => event_store[stream_name].length
          )
        end
      end

      def read(stream_name, direction: 'forward', start: 0, resolve_links: nil)
        response =
          if direction == 'forward'
            read_stream_forward(stream_name, start: start)
          else
            read_stream_backward(stream_name, start: start)
          end

        Response.new(response.to_json, 200)
      end

      def subscribe_to_stream
        # TODO: implement method body
      end

      def consume_feed
        # TODO: implement method body
      end

      def delete_stream(stream_name, hard_delete: false) # rubocop:disable Lint/UnusedMethodArgument
        event_store.delete(stream_name)
      end

      def link_to(stream_name, events)
        append_to_stream(stream_name, events)
      end

      def ack
        # TODO: implement method body
      end

      private

      attr_reader :endpoint, :per_page

      def initialize(host:, port:, per_page: 20)
        @endpoint = Endpoint.new(host: host, port: port)
        @per_page = per_page
        @event_store = {}
      end

      def read_stream_backward(stream_name, start: 0)
        return {} unless event_store.key?(stream_name)

        start = start == 'head' ? event_store[stream_name].length - 1 : start
        last_index = start - per_page
        entries = event_store[stream_name].select do |event|
          event['positionEventNumber'] > last_index &&
            event['positionEventNumber'] <= start
        end
        {
          'entries' => entries,
          'links' => links(stream_name, last_index, 'next', entries, per_page)
        }
      end

      def read_stream_forward(stream_name, start: 0)
        return {} unless event_store.key?(stream_name)

        last_index = start + per_page
        entries = event_store[stream_name].select do |event|
          event['positionEventNumber'] < last_index &&
            event['positionEventNumber'] >= start
        end
        {
          'entries' => entries,
          'links' => links(stream_name, last_index, 'previous', entries, per_page)
        }
      end

      def links(stream_name, batch_size, direction, entries, count)
        if entries.empty? || batch_size.negative?
          []
        else
          [{
            'uri' =>
              "http://#{endpoint.url}/streams/#{stream_name}/#{batch_size}/#{direction}/#{count}",
            'relation' => direction
          }]
        end
      end
    end
  end
end
