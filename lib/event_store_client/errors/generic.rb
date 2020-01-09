module EventStoreClient
  module Errors
    class Generic < StandardError
      def initialize(message, error_key)
        super(message || 'Generic error')
        self.error_key = error_key
      end

      private

      attr_accessor :error_key
    end
  end
end
