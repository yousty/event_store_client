# frozen_string_literal: true

module EventStoreClient
  class Subscriptions
    def create(subscriber, event_types)
      subscription = Subscription.new(subscriber, event_types: event_types, service: service)

      unless @subscriptions.detect { |sub| sub.name == subscription.name }
        connection.subscribe_to_stream(subscription.stream, subscription.name)
        subscriptions << subscription
      end

      subscription
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

    attr_reader :connection, :subscriptions, :service

    def initialize(connection:, service: 'default')
      @connection = connection
      @service = service
      @subscriptions = []
    end
  end
end
