# frozen_string_literal: true

require 'faraday'

module EventStoreClient
  module StoreAdapter
    module GRPC
      class Connection
        def call
          EventStore::Client::Streams::Streams::Stub.new(
            uri.to_s, :this_channel_is_insecure
          )
          # ADD AUTH(ENV['EVENT_STORE_USER'], ENV['EVENT_STORE_PASSWORD'])
          end
        end

        private

        def initialize(uri, options = {})
          @uri = uri
          @options = options
        end

        attr_reader :uri, :options
      end
    end
  end
end
