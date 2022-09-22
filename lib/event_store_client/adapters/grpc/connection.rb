# frozen_string_literal: true

require 'grpc'
require 'base64'
require 'net/http'

module EventStoreClient
  module GRPC
    class Connection
      include Configuration
      include Extensions::OptionsExtension

      option(:host) { Discover.current_member.host }
      option(:port) { Discover.current_member.port }
      option(:username) { config.eventstore_url.username }
      option(:password) { config.eventstore_url.password }
      option(:timeout) { config.eventstore_url.timeout }

      class << self
        include Configuration

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
        def new(*args, **kwargs, &blk)
          return super unless self == Connection

          if config.eventstore_url.tls
            Cluster::SecureConnection.new(*args, **kwargs, &blk)
          else
            Cluster::InsecureConnection.new(*args, **kwargs, &blk)
          end
        end

        # Checks if connection class is secure
        # @return [Boolean]
        def secure?
          self == Cluster::SecureConnection
        end
      end

      def call(stub_class)
        raise NotImplementedError
      end

      private

      # Common channel arguments for all GRPC requests.
      # Available channel arguments are described here
      # https://github.com/grpc/grpc/blob/master/include/grpc/impl/codegen/grpc_types.h
      # @return [Hash]
      def channel_args
        {
          # disable build-in GRPC retries functional
          'grpc.enable_retries' => 0,
          # These three options reduce delays between failed requests.
          'grpc.min_reconnect_backoff_ms' => 100, # milliseconds
          'grpc.max_reconnect_backoff_ms' => 100, # milliseconds
          'grpc.initial_reconnect_backoff_ms' => 100 # milliseconds
        }
      end
    end
  end
end
