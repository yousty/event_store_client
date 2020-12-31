# frozen_string_literal: true

module EventStoreClient
  class Broker
    include Configuration

    # Distributes known subscriptions to multiple threads
    # @param [EventStoreClient::Subscriptions]
    # @param wait [Boolean] (Optional) Controls if broker shold block
    #   main app process (useful for debugging)
    #
    def call(subscriptions, wait: false)
      subscriptions.each do |subscription|
        threads << Thread.new do
          connection.listen(subscription) do |event|
            subscription.subscriber.call(event)
          end
        end
      end
      threads.each(&:join) if wait
    end

    private

    attr_reader :connection
    attr_accessor :threads

    def initialize(connection:)
      @connection = connection
      @threads = []
    end
  end
end
