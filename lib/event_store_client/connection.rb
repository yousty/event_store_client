# frozen_string_literal: true

module EventStoreClient
  class Connection
    def publish(stream:, events:, expected_version: nil)
      serialized_events = events.map { |event| mapper.serialize(event) }
      client.append_to_stream(
        stream, serialized_events, expected_version: expected_version
      )
      serialized_events
    end

    def read(stream, direction: 'forward')
      response =
        client.read(stream, start: 0, direction: direction)
      return [] unless response.body
      JSON.parse(response.body)['entries'].map do |entry|
        event = EventStoreClient::Event.new(
          id: entry['eventId'],
          type: entry['eventType'],
          data: entry['data'],
          metadata: entry['metaData']
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
      ack_uri =
        body['links'].find { |link| link['relation'] == 'ackAll' }.
          try(:[], 'uri')
      events = body['entries'].map do |entry|
        event = EventStoreClient::Event.new(
          id: entry['eventId'],
          type: entry['eventType'],
          data: entry['data'] || '{}',
          metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
        )
        mapper.deserialize(event)
      end
      client.ack(ack_uri)
      events
    end

    private

    attr_reader :host, :port, :mapper, :per_page

    def config
      EventStoreClient::Configuration.instance
    end

    def initialize
      @host = config.host
      @port = config.port
      @per_page = config.per_page
      @mapper = config.mapper
    end

    def client
      @client ||=
        EventStoreClient::StoreAdapter::Api::Client.new(
          host: host, port: port, per_page: per_page
        )
    end
  end
end
