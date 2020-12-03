# frozen_string_literal: true

module EventStoreClient
  class Broker
    def call(subscriptions)
      subscriptions.each do |subscription|
        res = connection.consume_feed(subscription.stream, subscription.name) || []
        next if res[:events].none?
        res[:events].each { |event| subscription.subscriber.call(event) }
        connection.ack(res[:ack_uri])
      end
    end

    private

    attr_reader :connection

    def initialize(connection:)
      @connection = connection
    end
  end
end
