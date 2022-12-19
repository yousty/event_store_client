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

require 'event_store_client/mapper'

require 'event_store_client/adapters/grpc'

module EventStoreClient
  class << self
    # @param name [Symbol, String]
    def configure(name: :default)
      yield(config(name)) if block_given?
    end

    # @param name [Symbol, String]
    # @return [EventStore::Config]
    def config(name = :default)
      @config[name] ||= Config.new(name: name)
    end

    # @param config [Symbol, String]
    # @return [EventStore::GRPC::Client]
    def client(config: :default)
      GRPC::Client.new(_config(config))
    end

    # @return [void]
    def init_default_config
      @config = { default: Config.new }
    end

    private

    # @param config [Symbol, String]
    # @return [EventStoreClient::Config]
    # @raise [RuntimeError]
    def _config(config)
      return @config[config] if @config[config]

      error_message = <<~TEXT
        Could not find #{config.inspect} config. You can define it in next way:
        EventStoreClient.configure(name: #{config.inspect}) do |config|
          # your config goes here
        end
      TEXT
      raise error_message
    end
  end
  init_default_config
end
