# frozen_string_literal: true

module EventStoreClient
  class Broker
    include Configuration

    def call(subscriptions)
      threads = []
      subscriptions.each do |subscription|
        if config.adapter == :grpc
          read_grpc_subscription(subscription)
        else
          read_http_subscription(subscription)
        end
      end
      threads.each { |thr| thr.join }
    end

    private

    attr_reader :connection

    def initialize(connection:)
      @connection = connection
    end

    def read_grpc_subscription(subscription)
      threads << Thread.new do
        connection.consume_feed(subscription)
      end
    end

    def read_http_subscription(subscription)
      res = connection.consume_feed(subscription.stream, subscription.name) || { events: [] }
      next if res[:events].none?
      res[:events].each { |event| subscription.subscriber.call(event) }
      connection.ack(res[:ack_uri])
    end
  end
end
