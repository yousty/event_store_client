# frozen_string_literal: true

require 'grpc'
require 'base64'
require 'net/http'

module EventStoreClient
  module GRPC
    class Connection
      class << self
        # Resolve which connection class we instantiate, based on config.eventstore_url.tls config
        # option. If :new method is called from SecureConnection or InsecureConnection class - then
        # that particular class will be instantiated despite on config.eventstore_url.tls config
        # option. Example:
        #   ```ruby
        #   config.eventstore_url.tls = true
        #   Connection.new # => #<EventStoreClient::GRPC::Cluster::SecureConnection>
        #
        #   config.eventstore_url.tls = false
        #   Connection.new # => #<EventStoreClient::GRPC::Cluster::InsecureConnection>
        #
        #   Cluster::SecureConnection.new
        #   # => #<EventStoreClient::GRPC::Cluster::SecureConnection>
        #   Cluster::InsecureConnection.new
        #   # => #<EventStoreClient::GRPC::Cluster::InsecureConnection>
        #   ```
        # @param config [EventStoreClient::Config]
        def new(config:, **options)
          return super unless self == Connection

          if config.eventstore_url.tls
            Cluster::SecureConnection.new(config: config, **options)
          else
            Cluster::InsecureConnection.new(config: config, **options)
          end
        end

        # Checks if connection class is secure
        # @return [Boolean]
        def secure?
          self == Cluster::SecureConnection
        end
      end

      include Extensions::OptionsExtension

      option(:host) { Discover.current_member(config: config).host }
      option(:port) { Discover.current_member(config: config).port }
      option(:username) { config.eventstore_url.username }
      option(:password) { config.eventstore_url.password }
      option(:timeout) { config.eventstore_url.timeout }

      attr_reader :config
      private :config

      def initialize(config:, **options)
        @config = config
        super
      end

      def call(stub_class)
        raise NotImplementedError
      end
    end
  end
end
