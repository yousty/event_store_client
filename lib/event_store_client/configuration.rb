# frozen_string_literal: true

module EventStoreClient
  module Configuration
    # @return [EventStoreClient::Config]
    def config
      EventStoreClient.config
    end
  end
end
