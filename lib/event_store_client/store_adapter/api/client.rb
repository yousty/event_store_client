# frozen_string_literal: true

module EventStoreClient
  module StoreAdapter
    module Api
      class Client
        WrongExpectedEventVersion = Class.new(StandardError)

        def append_to_stream(stream_name, events, expected_version: nil)
          serialized_events = events.map { |event| mapper.serialize(event) }
          headers = {
            'ES-ExpectedVersion' => expected_version&.to_s
          }.reject { |_key, val| val.nil? || val.empty? }

          data = build_events_data(serialized_events)
          response = make_request(:post, "/streams/#{stream_name}", body: data, headers: headers)
          validate_response(response, expected_version)
          response
          serialized_events
        end

        def delete_stream(stream_name, hard_delete: false)
          headers = {
            'ES-HardDelete' => hard_delete.to_s
          }.reject { |_key, val| val.empty? }

          make_request(:delete, "/streams/#{stream_name}", body: {}, headers: headers)
        end

        def read(stream_name, direction: 'forward', start: 0, count: per_page, resolve_links: true)
          headers = {
            'ES-ResolveLinkTos' => resolve_links.to_s,
            'Accept' => 'application/vnd.eventstore.atom+json'
          }

          response = make_request(
            :get,
            "/streams/#{stream_name}/#{start}/#{direction}/#{count}",
            headers: headers
          )
          return [] if response.body.nil? || response.body.empty?
          JSON.parse(response.body)['entries'].map do |entry|
            deserialize_event(entry)
          end.reverse
        end

        def read_all_from_stream(stream, direction: 'forward', start: 0, resolve_links: true)
          count = per_page
          events = []
          failed_requests_count = 0

          while failed_requests_count < 3
            begin
              response =
                read(stream, start: start, direction: direction, resolve_links: resolve_links)
              failed_requests_count += 1 && next unless response.success? || response.status == 404
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

        def join_streams(name, streams)
          data = <<~STRING
            fromStreams(#{streams})
            .when({
              $any: function(s,e) {
                linkTo("#{name}", e)
              }
            })
          STRING

          make_request(
            :post,
            "/projections/continuous?name=#{name}&type=js&enabled=true&emit=true%26trackemittedstreams=true", # rubocop:disable Metrics/LineLength
            body: data,
            headers: {}
          )
        end

        def subscribe_to_stream(
          stream_name, subscription_name, stats: true, start_from: 0, retries: 5
        )
          make_request(
            :put,
            "/subscriptions/#{stream_name}/#{subscription_name}",
            body: {
              extraStatistics: stats,
              startFrom: start_from,
              maxRetryCount: retries,
              resolveLinkTos: true
            },
            headers: {
              'Content-Type' => 'application/json'
            }
          )
        end

        def consume_feed(
          stream_name,
          subscription_name,
          count: 1,
          long_poll: 0,
          resolve_links: true,
          per_page: 20
        )
          headers = long_poll.positive? ? { 'ES-LongPoll' => long_poll.to_s } : {}
          headers['Content-Type'] = 'application/vnd.eventstore.competingatom+json'
          headers['Accept'] = 'application/vnd.eventstore.competingatom+json'
          headers['ES-ResolveLinktos'] = resolve_links.to_s

          response = make_request(
            :get,
            "/subscriptions/#{stream_name}/#{subscription_name}/#{count}",
            headers: headers
          )

          return { events: [] } if response.body || response.body.empty?

          body = JSON.parse(response.body)

          ack_info = body['links'].find { |link| link['relation'] == 'ackAll' }
          return unless ack_info
          ack_uri = ack_info['uri']
          events = body['entries'].map do |entry|
            deserialize_event(entry)
          end
          { ack_uri: ack_uri, events: events }
        end

        def link_to(stream_name, events, expected_version: nil)
          data = build_linkig_data(events)
          headers = {
            'ES-ExpectedVersion' => expected_version&.to_s
          }.reject { |_key, val| val.nil? || val.empty? }

          response = make_request(
            :post,
            "/streams/#{stream_name}",
            body: data,
            headers: headers
          )
          validate_response(response, expected_version)
          true
        end

        def ack(url)
          make_request(:post, url)
        end

        private

        attr_reader :uri, :per_page, :connection_options, :mapper

        def initialize(uri, per_page: 20, mapper:, connection_options: {})
          @uri = uri
          @per_page = per_page
          @mapper = mapper
          @connection_options = connection_options
        end

        def build_events_data(events)
          [events].flatten.map do |event|
            {
              eventId: event.id,
              eventType: event.type,
              data: event.data,
              metadata: event.metadata
            }
          end
        end

        def build_linkig_data(events)
          [events].flatten.map do |event|
            {
              eventId: event.id,
              eventType: '$>',
              data: event.title,
            }
          end
        end

        def make_request(method_name, path, body: {}, headers: {})
          method = RequestMethod.new(method_name)
          connection.send(method.to_s, path) do |req|
            req.headers = req.headers.merge(headers)
            req.body = body.is_a?(String) ? body : body.to_json
            req.params['embed'] = 'body' if method == :get
          end
        end

        def connection
          @connection ||= Api::Connection.new(uri, connection_options).call
        end

        def validate_response(resp, expected_version)
          return unless resp.status == 400 && resp.reason_phrase == 'Wrong expected EventNumber'
          raise WrongExpectedEventVersion.new(
            "current version: #{resp.headers.fetch('es-currentversion')} | "\
            "expected: #{expected_version}"
          )
        end

        def deserialize_event(entry)
          event = EventStoreClient::Event.new(
            id: entry['eventId'],
            title: entry['title'],
            type: entry['eventType'],
            data: entry['data'] || '{}',
            metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
          )

          mapper.deserialize(event)
        end
      end
    end
  end
end
