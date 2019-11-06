# frozen_string_literal: true

module Eventstore
  module Client
    module Api
      class Client
        def read_stream_backward(stream_name, start: 0, count: per_page)
          make_request(:get, "/streams/#{stream_name}/#{start}/backward/#{count}")
        end

        def read_stream_forward(stream_name, start: 0, count: per_page)
          make_request(:get, "/streams/#{stream_name}/#{start}/forward/#{count}")
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
            # req.body['embed'] = 'body' if method == :get
          end
        end

        def connection
          @connection ||= Api::Connection.new(endpoint).call
        end
      end
    end
  end
end
