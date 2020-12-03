# frozen_string_literal: true

module EventStoreClient
  class Subscriptions
    def create(subscriber, event_types)
      subscription = Subscription.new(subscriber, event_types: event_types, service: service)
      connection.join_streams(subscriber.class.name, subscription.observed_streams)
      unless @subscriptions.detect { |sub| sub.name == subscription.name }
        create_subscription(subscription)
      end

      subscriptions << subscription
    end

    def each
      subscriptions.each do |subscription|
        yield(subscription)
      end
    end

    def get_updates(subscription)
      connection.consume_feed(subscription.stream, subscription.name)
    end

    private

    def create_subscription(subscription)
      # store position somewhere.
      connection.join_streams(subscription.name, subscription.observed_streams)
      connection.subscribe_to_stream(subscription.stream, name: subscription.name)
    end

    attr_reader :connection, :subscriptions, :service

    def initialize(connection:, service: 'default')
      @connection = connection
      @service = service
      @subscriptions = []
    end
  end
end
