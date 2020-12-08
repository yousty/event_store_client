# frozen_string_literal: true

require 'dry-configurable'

module EventStoreClient
  extend Dry::Configurable

  # Supported adapters: %i[api in_memory grpc]
  #
  setting :adapter, :grpc

  setting :error_handler
  setting :eventstore_url, 'http://localhost:2113' do |value|
    value.is_a?(URI) ? value : URI(value)
  end

  setting :eventstore_user, 'admin'
  setting :eventstore_password, 'changeit'

  setting :db_port, 2113

  setting :per_page, 20
  setting :pid_path, 'tmp/poll.pid'

  setting :service_name, 'default'

  setting :mapper, Mapper::Default.new

  def self.configure
    yield(config) if block_given?

    config.adapter =
      case config.adapter
      when :api
        StoreAdapter::Api::Client.new(
          config.eventstore_url,
          per_page: config.per_page,
          mapper: config.mapper,
          connection_options: {}
        )
      when :grpc
        StoreAdapter::GRPC::Client.new(
          config.eventstore_url,
          per_page: config.per_page,
          mapper: config.mapper,
          connection_options: {}
        )
      else
        StoreAdapter::InMemory.new(
          mapper: config.mapper, per_page: config.per_page
        )
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
