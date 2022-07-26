# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class SecureConnection < Connection
        CertificateLookupError = Class.new(StandardError)

        # @param stub_class GRPC request stub class. E.g. EventStore::Cluster::Gossip::Service::Stub
        # @return instance of the given stub_class class
        def call(stub_class)
          stub_class.new(
            "#{host}:#{port}",
            channel_credentials,
            channel_args: { 'authorization' => "Basic #{credentials_string}" }
          )
        end

        # @return [String]
        def credentials_string
          Base64.encode64("#{username}:#{password}").delete("\n")
        end

        private

        # @return [GRPC::Core::ChannelCredentials]
        def channel_credentials
          certificate =
            if config.eventstore_url.tls_ca_file
              File.read(config.eventstore_url.tls_ca_file)
            else
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
            retry if retries <= attempts
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
