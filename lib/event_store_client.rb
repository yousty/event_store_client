# frozen_string_literal: true

require 'json'
require 'set'

require 'event_store_client/serializer/json'
require 'event_store_client/serializer/event_serializer'
require 'event_store_client/serializer/event_deserializer'

require 'event_store_client/extensions/options_extension'

require 'event_store_client/utils'

require 'event_store_client/connection/url'
require 'event_store_client/connection/url_parser'
require 'event_store_client/deserialized_event'
require 'event_store_client/serialized_event'
require 'event_store_client/config'
require 'event_store_client/configuration'

require 'event_store_client/mapper'

require 'event_store_client/adapters/grpc'

module EventStoreClient
  class << self
    def configure
      yield(config) if block_given?
    end

    # @return [EventStore::Config]
    def config
      @config ||= Config.new
    end

    # @return [EventStore::GRPC::Client]
    def client
      GRPC::Client.new
    end
  end
end
