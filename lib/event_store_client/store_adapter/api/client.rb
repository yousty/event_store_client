# frozen_string_literal: true

module EventStoreClient
  module StoreAdapter
    module Api
      class Client
        def append_to_stream(stream_name, events, expected_version: nil)
          headers = {
            'ES-ExpectedVersion' => expected_version.to_s
          }.reject { |_key, val| val.empty? }

          data = [events].flatten.map do |event|
            {
              eventId: event.id,
              eventType: event.type,
              data: event.data,
              metadata: event.metadata
            }
          end

          make_request(:post, "/streams/#{stream_name}", body: data, headers: headers)
        end

        def delete_stream(stream_name, hard_delete)
          headers = JSON_HEADERS.merge('ES-HardDelete' => hard_delete.to_s)
          make_request(:delete, "/streams/#{stream_name}", {}, headers)
        end

        def read(stream_name, direction: 'forward', start: 0, count: per_page)
          make_request(:get, "/streams/#{stream_name}/#{start}/#{direction}/#{count}")
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
              "Content-Type" => "application/json"
            }
          )
        end

        def consume_feed(
          stream_name,
          subscription_name,
          start: 0,
          count: 1,
          long_pool: 0
        )
          headers = long_pool > 0 ? { "ES-LongPoll" => "#{long_pool}" } : {}
          headers['Content-Type'] = 'application/vnd.eventstore.competingatom+json'
          headers['Accept'] = 'application/vnd.eventstore.competingatom+json'
          make_request(
          :get,
            "/subscriptions/#{stream_name}/#{subscription_name}/#{count}",
            headers: headers
          )
        end

        def ack(url)
          make_request(:post, url)
        end

        private

        attr_reader :endpoint, :per_page

        def initialize(host:, port:, per_page: 20)
          @endpoint = Endpoint.new(host: host, port: port)
          @per_page = per_page
        end

        def make_request(method_name, path, body: {}, headers: {})
          method = RequestMethod.new(method_name)
          connection.send(method.to_s, path) do |req|
            req.headers = req.headers.merge(headers)
            req.body = body.to_json
            req.params['embed'] = 'body' if method == :get
          end
        end

        def connection
          @connection ||= Api::Connection.new(endpoint).call
        end
      end
    end
  end
end
