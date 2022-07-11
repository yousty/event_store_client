# frozen_string_literal: true

require 'event_store_client/adapters/grpc/command_registrar'

module EventStoreClient
  module GRPC
    module Commands
      class Command
        def self.inherited(klass)
          super
          klass.class_eval do
            include Dry::Monads[:try, :result]

            def self.use_request(request_klass)
              CommandRegistrar.register_request(self, request: request_klass)
            end

            def self.use_service(service_klass)
              CommandRegistrar.register_service(self, service: service_klass)
            end

            def request
              CommandRegistrar.request(self.class)
            end

            def service
              CommandRegistrar.service(self.class, options: { credentials: credentials })
            end
          end
        end

        include Configuration

        attr_reader :username, :password
        private :username, :password

        # @param credentials [Hash]
        # @option [String] :username
        # @option [String] :password
        def initialize(credentials = {})
          @username = credentials[:username]
          @password = credentials[:password]
        end

        def metadata
          { 'authorization' => "Basic #{credentials.delete("\n")}" }
        end

        private

        def credentials
          username = self.username || config.eventstore_user
          password = self.password || config.eventstore_user
          Base64.encode64("#{username}:#{password}")
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
