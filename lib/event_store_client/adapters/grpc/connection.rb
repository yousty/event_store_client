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
      option(:timeout) { config.eventstore_url }

      class SocketErrorRetryFailed < StandardError; end

      class << self
        include Configuration

        def new(*args, **kwargs, &blk)
          return super unless self == Connection

          if secure?
            Cluster::SecureConnection.new(*args, **kwargs, &blk)
          else
            Cluster::InsecureConnection.new(*args, **kwargs, &blk)
          end
        end

        def secure?
          config.eventstore_url.tls
        end
      end

      def call(stub_class)
        raise NotImplementedError
      end

      def credentials_string
      end
    end
  end
end
