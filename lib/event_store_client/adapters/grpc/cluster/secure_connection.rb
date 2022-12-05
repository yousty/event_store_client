# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class SecureConnection < Connection
        CertificateLookupError = Class.new(StandardError)

        # @param stub_class GRPC request stub class. E.g. EventStore::Client::Gossip::Gossip::Stub
        # @return instance of the given stub_class class
        def call(stub_class)
          config.logger&.debug("Using secure connection with credentials #{username}:#{password}.")
          stub_class.new(
            "#{host}:#{port}",
            channel_credentials,
            channel_args: config.channel_args,
            timeout: (timeout / 1000.0 if timeout)
          )
        end

        private

        # @return [GRPC::Core::ChannelCredentials]
        def channel_credentials
          certificate =
            if config.eventstore_url.tls_ca_file
              config.logger&.debug('Picking certificate from tlsCAFile option.')
              File.read(config.eventstore_url.tls_ca_file)
            else
              config.logger&.debug('Resolving certificate from current member.')
              cert.to_s
            end

          ::GRPC::Core::ChannelCredentials.new(certificate)
        end

        # rubocop:disable Metrics/AbcSize

        # @return [String, nil] returns the X.509 certificates the server presented
        # @raise [EventStoreClient::GRPC::Cluster::SecureConnection::CertificateLookupError]
        def cert
          retries = 0

          begin
            Net::HTTP.start(host, port, use_ssl: true, verify_mode: verify_mode, &:peer_cert)
          rescue SocketError => e
            attempts = config.eventstore_url.ca_lookup_attempts
            sleep config.eventstore_url.ca_lookup_interval / 1000.0
            retries += 1
            if retries <= attempts
              config.logger&.debug("Failed to lookup certificate. Reason: #{e.class}. Retying.")
              retry
            end
            raise(
              CertificateLookupError,
              "Failed to get X.509 certificate after #{attempts} attempts."
            )
          end
        end
        # rubocop:enable Metrics/AbcSize

        # @return [Integer] SSL verify mode
        def verify_mode
          return OpenSSL::SSL::VERIFY_PEER if config.eventstore_url.tls_verify_cert

          OpenSSL::SSL::VERIFY_NONE
        end
      end
    end
  end
end
