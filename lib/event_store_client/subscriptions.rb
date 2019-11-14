# frozen_string_literal: true

module EventStoreClient
  class Subscriptions
    def create(subscriber, event_types)
      event_types.each do |type|
        subscription = subscriptions[type.to_s] || Subscription.new(type: type, name: service)
        subscription.subscribers |= [subscriber]
        create_subscription(subscription) unless @subscriptions.key?(type.to_s)
        @subscriptions[type.to_s] = subscription
      end
    end

    def each
      subscriptions.values.each do |subscription|
        yield(subscription)
      end
    end

    def get_updates(subscription)
      connection.consume_feed(subscription.stream, subscription.name)
    end

    private

    def create_subscription(subscription)
      connection.subscribe(subscription.stream, name: subscription.name)
    end

    attr_reader :connection, :subscriptions, :service

    def initialize(connection:, service: 'default')
      @connection = connection
      @service = service
      @subscriptions = {}
    end
  end
end
