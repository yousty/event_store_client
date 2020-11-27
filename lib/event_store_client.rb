# frozen_string_literal: true

module EventStoreClient
  def self.configure(&block)
    config = Configuration.instance
    config.configure(&block)
  end
end

require 'event_store_client/configuration'
require 'event_store_client/types'
require 'event_store_client/event'
require 'event_store_client/deserialized_event'

require 'event_store_client/serializer/json'

require 'event_store_client/mapper'

require 'event_store_client/endpoint'

require 'event_store_client/store_adapter'

require 'event_store_client/subscription'
require 'event_store_client/subscriptions'
require 'event_store_client/broker'
require 'event_store_client/client'
