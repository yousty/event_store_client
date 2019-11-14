# frozen_string_literal: true

module EventStoreClient
  class Connection
    def publish(stream:, event:, expected_version: nil)
      serialized_event = mapper.serialize(event)
      client.append_to_stream(
        stream, serialized_event, expected_version: expected_version
      )
      serialized_event
    end

    def read(stream, direction: 'forward')
      response =
        if direction == 'forward'
          client.read_stream_forward(stream, start: 0)
        else
          client.read_stream_backward(stream, start: 0)
        end
      return [] unless response.body
      JSON.parse(response.body)['entries'].map do |entry|
        event = EventStoreClient::Event.new(
          id: entry['eventId'],
          type: entry['eventType'],
          data: entry['data'],
          metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
        )
        mapper.deserialize(event)
      end
    end

    def delete_stream(stream); end

    def subscribe(stream, name:)
      client.subscribe_to_stream(stream, name)
    end

    def consume_feed(stream, subscription)
      response = client.consume_feed(stream, subscription)
      return [] unless response.body
      body = JSON.parse(response.body)
      ack_uri = body['links'].find { |link| link['relation'] == 'ackAll' }.
        try(:[], 'uri')
      client.ack(ack_uri)
      body['entries'].map do |entry|
        event = EventStoreClient::Event.new(
          id: entry['eventId'],
          type: entry['eventType'],
          data: entry['data'] || '{}',
          metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
        )
        mapper.deserialize(event)
      end
    end

    private

    attr_reader :host, :port, :mapper, :per_page

    def config
      EventStoreClient.configuration
    end

    def initialize
      @host = config.host
      @port = config.port
      @per_page = config.per_page
      @mapper = config.mapper
    end

    def client
      @client ||=
        EventStoreClient::Adapter::Api::Client.new(
          host: host, port: port, per_page: per_page
        )
    end
  end
end
