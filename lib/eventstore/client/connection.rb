# frozen_string_literal: true

module Eventstore
  module Client
    class Connection
      def publish(stream:, domain_event:, expected_version: nil)
        event = adapter.new(domain_event)
        client.append_to_stream(
          stream, event, expected_version: expected_version
        )
        event
      end

      def read(stream, direction: 'forward')
        if direction == 'forward'
          client.read_stream_forward(stream, start: 0)
        else
          client.read_stream_backward(stream, start: 0)
        end
        res = JSON.parse[response.body]['entries'].map do |entry|
          Event.new(
            id: entry['eventId'],
            type: entry['eventType'],
            data: JSON.parse(event.data),
            metadata: event['isMetaData'] ? JSON.parse(event['metaData']) : {}
          )
        end
      end

      def delete_stream(stream)

      end

      private

      attr_reader :host, :port

      def initialize
        @host = "localhost"
        @port = 2113
        @per_page = 20

        yield(self) if block_given?
      end

      def client
        @client ||= Api::Client.new(host: host, port: port, per_page: per_page)
      end
    end
  end
end
