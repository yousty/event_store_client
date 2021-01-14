# frozen_string_literal: true

require 'dry-monads'
require 'event_store_client/adapters/grpc/command_registrar'

module EventStoreClient
  module HTTP
    module Commands
      class Command
        def self.inherited(klass)
          super
          klass.class_eval do
            include Dry::Monads[:result]
          end
        end

        protected

        attr_reader :connection

        def initialize(connection)
          @connection = connection
        end
      end
    end
  end
end
