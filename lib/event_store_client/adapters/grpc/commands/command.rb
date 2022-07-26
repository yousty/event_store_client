# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      class Command
        module ClassMethods
          def use_request(request_klass)
            CommandRegistrar.register_request(self, request: request_klass)
          end

          def use_service(service_klass)
            CommandRegistrar.register_service(self, service: service_klass)
          end
        end

        def self.inherited(klass)
          klass.extend(ClassMethods)
        end

        include Configuration
        include Dry::Monads[:try, :result]

        attr_reader :connection
        private :connection

        # @param conn_options [Hash]
        # @option conn_options [String] :host
        # @option conn_options [Integer] :port
        # @option conn_options [String] :username
        # @option conn_options [String] :password
        def initialize(**conn_options)
          @connection = EventStoreClient::GRPC::Connection.new(**conn_options)
        end

        def metadata
          return {} unless connection.credentials_string

          { 'authorization' => "Basic #{connection.credentials_string}" }
        end

        def request
          CommandRegistrar.request(self.class)
        end

        def service
          connection.call(CommandRegistrar.service(self.class))
        end

        private

        def connection_options
          {
            username: connection.username,
            password: connection.password
          }
        end

        def retry_request
          retries = 0
          begin
            yield
          rescue ::GRPC::Unavailable => e
            sleep config.grpc_unavailable_retry_sleep
            retries += 1
            retry if retries <= config.grpc_unavailable_retry_count
            raise
          end
        end
      end
    end
  end
end
