# frozen_string_literal: true

require 'faraday'

module EventStoreClient
  module HTTP
    class Connection
      include Configuration

      def call
        Faraday.new(
          {
            url: uri.to_s,
            headers: DEFAULT_HEADERS
          }.merge(options)
        ) do |conn|
          conn.basic_auth(config.eventstore_user, config.eventstore_password)
          conn.adapter Faraday.default_adapter
        end
      end

      private

      def initialize(uri, options = {})
        @uri = uri
        @options = options
      end

      attr_reader :uri, :options

      DEFAULT_HEADERS = {
        'Content-Type' => 'application/vnd.eventstore.events+json'
        # 'Accept' => 'application/vnd.eventstore.atom+json',
        # 'ES-EventType' => 'UserRegistered',
        # 'ES-EventId' => SecureRandom.uuid
      }.freeze
    end
  end
end
