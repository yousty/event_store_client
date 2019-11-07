# frozen_string_literal: true

require 'faraday'

module Eventstore
  module Client
    module Adapter
      module Api
        class Connection
          def call
            Faraday.new(
              url: endpoint.url,
              headers: DEFAULT_HEADERS
            ) do |conn|
              conn.basic_auth('admin', 'changeit')
              conn.adapter Faraday.default_adapter
            end
          end

          private

          def initialize(endpoint)
            @endpoint = endpoint
          end

          attr_reader :endpoint

          DEFAULT_HEADERS = {
            'Content-Type' => 'application/vnd.eventstore.events+json',
            'Accept' => 'application/vnd.eventstore.atom+json'
            # 'ES-EventType' => 'UserRegistered',
            # 'ES-EventId' => SecureRandom.uuid
          }.freeze
        end
      end
    end
  end
end
