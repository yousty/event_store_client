# frozen_string_literal: true

require 'dry-configurable'
require 'event_store_client/error_handler'
module EventStoreClient
  extend Dry::Configurable

  # Supported adapters: %i[api in_memory grpc]
  #
  setting :adapter, :grpc
  setting :verify_ssl, true

  setting :error_handler, ErrorHandler.new
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
  end

  def self.adapter
    @adapter =
      case config.adapter
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
