# frozen_string_literal: true

class TestHelper
  class << self
    def configure_grpc
      EventStoreClient.configure do |config|
        config.eventstore_url = ENV.fetch('EVENTSTORE_URL') { 'esdb://admin:changeit@localhost:2115/?tls=false' }
        config.adapter_type = :grpc
        config.error_handler = proc {}
        config.subscriptions_repo = EventStoreClient::CatchUpSubscriptions.new(
          connection: EventStoreClient.client,
          subscription_store: DummySubscriptionStore.new('dummy-subscription-store')
        )
      end
    end
  end
end
