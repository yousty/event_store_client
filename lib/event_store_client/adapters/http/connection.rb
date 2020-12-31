# frozen_string_literal: true

require 'faraday'
require 'event_store_client/adapters/http/request_method'

module EventStoreClient
  module HTTP
    class Connection
      include Configuration

      def call(method_name, path, body: {}, headers: {})
        method = RequestMethod.new(method_name)
        connection.send(method.to_s, path) do |req|
          req.headers = req.headers.merge(headers)
          req.body = body.is_a?(String) ? body : body.to_json
          req.params['embed'] = 'body' if method == :get
        end
      end

      private

      def initialize(uri, options = {})
        @connection = set_connection(uri, options)
      end

      attr_reader:options, :connection

      DEFAULT_HEADERS = {
        'Content-Type' => 'application/vnd.eventstore.events+json'
        # 'Accept' => 'application/vnd.eventstore.atom+json',
      }.freeze

      def set_connection(uri, connection_options)
        Faraday.new(
          {
            url: uri.to_s,
            headers: DEFAULT_HEADERS
          }.merge(connection_options)
        ) do |conn|
          conn.basic_auth(config.eventstore_user, config.eventstore_password)
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
