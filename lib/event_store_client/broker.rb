# frozen_string_literal: true

module EventStoreClient
  class Broker
    def call(subscriptions)
      subscriptions.each do |subscription|
        new_events = connection.consume_feed(subscription.stream, subscription.name)
        next if new_events.none?
        new_events.each do |event|
          subscription.subscribers.each do |subscriber|
            subscriber.call(event)
          end
        end
      end
    end

    private

    attr_reader :connection

    def initialize(connection:)
      @connection = connection
    end
  end
end
