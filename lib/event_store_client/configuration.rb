# frozen_string_literal: true

require 'dry-configurable'
require 'event_store_client/error_handler'
require 'event_store_client/deserialized_event'

module EventStoreClient
  class << self
    def configure
      yield(config) if block_given?
    end

    def config
      @config ||= Class.new do
        extend Dry::Configurable

        # Supported adapter_types: %i[http in_memory grpc]
        #
        setting :adapter_type, default: :grpc

        setting :insecure, default: false

        setting :error_handler, default: ErrorHandler.new
        setting :eventstore_url,
                default: 'esdb://localhost:2115',
                constructor:
                  proc { |value|
                    value.is_a?(Connection::Url) ? value : Connection::UrlParser.new.call(value)
                  }
        setting :eventstore_user, default: 'admin'
        setting :eventstore_password, default: 'changeit'

        setting :per_page, default: 20

        setting :service_name, default: 'default'

        setting :mapper, default: Mapper::Default.new

        setting :default_event_class, default: DeserializedEvent

        setting :subscriptions_repo

        setting :logger

        setting :grpc_unavailable_retry_sleep, default: 0.5
        setting :grpc_unavailable_retry_count, default: 3

        setting :skip_deserialization, default: false
        setting :skip_decryption, default: false
      end
      @config.config
    end

    def client
      case config.adapter_type
      when :http
        require 'event_store_client/adapters/http'
        HTTP::Client.new
      when :grpc
        require 'event_store_client/adapters/grpc'
        GRPC::Client.new
      else
        require 'event_store_client/adapters/in_memory'
        InMemory.new(
          mapper: config.mapper, per_page: config.per_page
        )
      end
    end
  end

  # Configuration module to be included in classes required configured variables
  # Usage: include EventStore::Configuration
  # config.eventstore_url
  #
  module Configuration
    # An instance of the EventStoreClient's configuration
    #
    def config
      EventStoreClient.config
    end
  end
end
