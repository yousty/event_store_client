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

    def read(stream, direction:, start:, all:, resolve_links: true)
      return read_all_from_stream(stream, start: start, resolve_links: resolve_links) if all
      read_from_stream(
        stream, direction: direction, start: start, resolve_links: resolve_links
      )
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
          title: entry['title'],
          type: entry['eventType'],
          data: entry['data'] || '{}',
          metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
        )
        mapper.deserialize(event)
      end
      client.ack(ack_uri)
      events
    end

    def link_to(stream, events, expected_version: nil)
      client.link_to(stream, events, expected_version: expected_version)

      true
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

    def read_from_stream(stream, direction:, start:, resolve_links:)
      response =
        client.read(
          stream, start: start, direction: direction, resolve_links: resolve_links
        )
      return [] if response.body.nil? || response.body.empty?
      JSON.parse(response.body)['entries'].map do |entry|
        deserialize_event(entry)
      end.reverse
    end

    def read_all_from_stream(stream, start:, resolve_links:)
      count = per_page
      events = []
      failed_requests_count = 0

      while failed_requests_count < 3
        begin
          response =
            client.read(stream, start: start, direction: 'forward', resolve_links: resolve_links)
          failed_requests_count += 1 && next unless response.success?
        rescue Faraday::ConnectionFailed
          failed_requests_count += 1
          next
        end
        failed_requests_count = 0
        break if response.body.nil? || response.body.empty?
        entries = JSON.parse(response.body)['entries']
        break if entries.empty?
        events += entries.map { |entry| deserialize_event(entry) }.reverse
        start += count
      end
      events
    end

    def deserialize_event(entry)
      event = EventStoreClient::Event.new(
        id: entry['eventId'],
        title: entry['title'],
        type: entry['eventType'],
        data: entry['data'],
        metadata: entry['metaData']
      )
      mapper.deserialize(event)
    end
  end
end
