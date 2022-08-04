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
            channel_args: channel_args,
            timeout: (timeout / 1000.0 if timeout)
          )
        end

        private

        # @return [GRPC::Core::ChannelCredentials]
        def channel_credentials
          certificate =
            if config.eventstore_url.tls_ca_file
              config.logger&.debug("Picking certificate from tlsCAFile option.")
              File.read(config.eventstore_url.tls_ca_file)
            else
              config.logger&.debug("Resolving certificate from current member.")
              get_cert.to_s
            end

          ::GRPC::Core::ChannelCredentials.new(certificate)
        end

        def get_cert
          retries = 0
          verify_mode =
            if config.eventstore_url.tls_verify_cert
              OpenSSL::SSL::VERIFY_PEER
            else
              OpenSSL::SSL::VERIFY_NONE
            end
          begin
            Net::HTTP.start(
              host, port,
              use_ssl: true,
              verify_mode: verify_mode,
              &:peer_cert
            )
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
      end
    end
  end
end
