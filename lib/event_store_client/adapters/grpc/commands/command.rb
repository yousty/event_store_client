# frozen_string_literal: true

require 'dry-monads'
require 'event_store_client/adapters/grpc/command_registrar'

module EventStoreClient
  module GRPC
    module Commands
      class Command
        include Configuration

        class GRPCUnavailableRetryFailed < StandardError; end

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
              CommandRegistrar.service(self.class)
            end
          end
        end

        def metadata
          credentials =
            Base64.encode64("#{config.eventstore_user}:#{config.eventstore_password}")
          { 'authorization' => "Basic #{credentials.delete("\n")}" }
        end
      end
    end
  end
end
