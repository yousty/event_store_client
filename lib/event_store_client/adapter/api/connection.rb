# frozen_string_literal: true

require 'faraday'

module EventStoreClient
  module Adapter
    module Api
      class Connection
        def call
          Faraday.new(
            url: endpoint.url,
            headers: DEFAULT_HEADERS
          ) do |conn|
            conn.basic_auth(ENV['EVENT_STORE_USER'], ENV['EVENT_STORE_PASSWORD'])
            conn.adapter Faraday.default_adapter
          end
        end

        private

        def initialize(endpoint)
          @endpoint = endpoint
        end

        attr_reader :endpoint

        DEFAULT_HEADERS = {
          'Content-Type' => 'application/vnd.eventstore.events+json'
          # 'Accept' => 'application/vnd.eventstore.atom+json',
          # 'ES-EventType' => 'UserRegistered',
          # 'ES-EventId' => SecureRandom.uuid
        }.freeze
      end
    end
  end
end
