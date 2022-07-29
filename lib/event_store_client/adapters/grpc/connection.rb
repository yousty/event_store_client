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

      class SocketErrorRetryFailed < StandardError; end

      class << self
        include Configuration

        def new(*args, **kwargs, &blk)
          return super unless self == Connection

          if config.eventstore_url.tls
            Cluster::SecureConnection.new(*args, **kwargs, &blk)
          else
            Cluster::InsecureConnection.new(*args, **kwargs, &blk)
          end
        end

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
