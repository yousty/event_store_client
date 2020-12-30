# frozen_string_literal: true

require 'dry-monads'
require 'event_store_client/configuration'
require 'event_store_client/adapters/grpc/command_registrar'

module EventStoreClient
  module GRPC
    module Commands
      class Command
        def self.inherited(klass)
          super
          klass.class_eval do
            include Dry::Monads[:result]

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
      end
    end
  end
end
