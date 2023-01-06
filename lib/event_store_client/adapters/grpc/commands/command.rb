# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      class Command
        class << self
          def use_request(request_klass)
            CommandRegistrar.register_request(self, request: request_klass)
          end

          def use_service(service_klass)
            CommandRegistrar.register_service(self, service: service_klass)
          end
        end

        attr_reader :connection, :config
        private :connection, :config

        # @param config [EventStoreClient::Config]
        # @param conn_options [Hash]
        # @option conn_options [String] :host
        # @option conn_options [Integer] :port
        # @option conn_options [String] :username
        # @option conn_options [String] :password
        def initialize(config:, **conn_options)
          @config = config
          @connection = EventStoreClient::GRPC::Connection.new(config: config, **conn_options)
        end

        # Override it in your implementation of command.
        def call
          raise NotImplementedError
        end

        # @return [Hash]
        def metadata
          return {} unless connection.class.secure?

          credentials =
            Base64.encode64("#{connection.username}:#{connection.password}").delete("\n")
          { 'authorization' => "Basic #{credentials}" }
        end

        # @return GRPC params class to be used in the request.
        #   E.g.EventStore::Client::Streams::ReadReq
        def request
          CommandRegistrar.request(self.class)
        end

        # @return GRPC request stub class. E.g. EventStore::Client::Streams::Streams::Stub
        def service
          connection.call(CommandRegistrar.service(self.class))
        end

        # @return [Hash] connection options' hash
        def connection_options
          @connection.options_hash
        end

        private

        def retry_request(skip_retry: false)
          return yield if skip_retry

          retries = 0
          begin
            yield
          rescue ::GRPC::Unavailable => e
            sleep config.eventstore_url.grpc_retry_interval / 1000.0
            retries += 1
            if retries <= config.eventstore_url.grpc_retry_attempts
              config.logger&.debug("Request failed. Reason: #{e.class}. Retying.")
              retry
            end
            Discover.current_member(config: config)&.failed_endpoint = true
            raise
          end
        end
      end
    end
  end
end
