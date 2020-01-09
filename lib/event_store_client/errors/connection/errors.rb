module EventStoreClient
  module Errors
    module Connection
      class GenericError < EventStoreClient::Errors::Generic
        def initialize(message: nil, status: nil, error_key: nil)
          super(message || 'Generic connection error', error_key)
          self.status = status
        end

        private

        attr_accessor :status
      end

      class AuthorizationFailed < GenericError
        def initialize(message: 'Authorization failed', status: 401, error_key: nil)
          super(message: message, status: status, error_key: error_key)
        end
      end
    end
  end
end
