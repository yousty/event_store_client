# frozen_string_literal: true

require 'grpc'
require 'base64'
require 'net/http'

module EventStoreClient
  module GRPC
    class Connection
      include Configuration

      class SocketErrorRetryFailed < StandardError; end

      # Initializes the proper stub with the necessary credentials
      # to create working gRPC connection - Refer to generated grpc files
      # @return [Stub] Instance of a given `Stub` klass
      #
      def call(stub_klass, options: {})
        return insecure_stub(stub_klass) if config.insecure

        secure_stub(stub_klass, options[:credentials])
      end

      private

      attr_reader :cert

      def initialize
        retries ||= 0
        @cert =
          Net::HTTP.start(
            config.eventstore_url.host, config.eventstore_url.port,
            use_ssl: true,
            verify_mode: config.verify_ssl || OpenSSL::SSL::VERIFY_NONE,
            &:peer_cert
          )
      rescue SocketError
        sleep config.socket_error_retry_sleep
        retry if (retries += 1) <= config.socket_error_retry_count
        raise SocketErrorRetryFailed
      end

      def channel_credentials
        ::GRPC::Core::ChannelCredentials.new(cert.to_s)
      end

      def secure_stub(stub_klass, credentials)
        credentials ||=
          Base64.encode64("#{config.eventstore_user}:#{config.eventstore_password}")
        stub_klass.new(
          "#{config.eventstore_url.host}:#{config.eventstore_url.port}",
          channel_credentials,
          channel_args: { 'authorization' => "Basic #{credentials.delete("\n")}" }
        )
      end

      def insecure_stub(stub_klass)
        stub_klass.new(
          "#{config.eventstore_url.host}:#{config.eventstore_url.port}",
          :this_channel_is_insecure
        )
      end
    end
  end
end
