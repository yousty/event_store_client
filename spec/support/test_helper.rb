# frozen_string_literal: true

class TestHelper
  class << self
    def configure_grpc
      EventStoreClient.configure do |config|
        config.eventstore_url = ENV.fetch('EVENTSTORE_URL') { 'http://localhost:2113' }
        config.adapter_type = :grpc
        config.eventstore_user = ENV.fetch('EVENTSTORE_USER') { 'admin' }
        config.eventstore_password = ENV.fetch('EVENTSTORE_PASSWORD') { 'changeit' }
        config.verify_ssl = false
        config.insecure = true
        config.service_name = ''
        config.error_handler = proc {}
        config.subscriptions_repo = EventStoreClient::CatchUpSubscriptions.new(
          connection: EventStoreClient.client,
          subscription_store: DummySubscriptionStore.new('dummy-subscription-store')
        )
      end
    end
  end
end
