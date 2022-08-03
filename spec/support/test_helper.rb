# frozen_string_literal: true

class TestHelper
  class << self
    def configure_grpc
      EventStoreClient.configure do |config|
        config.eventstore_url =
          ENV.fetch('EVENTSTORE_URL') { 'esdb://localhost:2115/?tls=false&timeout=1000' }
        config.error_handler = proc {}
        config.subscriptions_repo = EventStoreClient::CatchUpSubscriptions.new(
          connection: EventStoreClient.client,
          subscription_store: DummySubscriptionStore.new('dummy-subscription-store')
        )
      end
    end

    def root_path
      File.expand_path('../..', __dir__)
    end
  end
end
