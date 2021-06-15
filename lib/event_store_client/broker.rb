# frozen_string_literal: true

module EventStoreClient
  class Broker
    include Configuration

    # Distributes known subscriptions to multiple threads
    # @param [EventStoreClient::Subscriptions]
    # @param wait [Boolean] (Optional) Controls if broker should block
    #   main app process (useful for debugging)
    #
    def call(subscriptions, wait: false)
      Signal.trap('TERM') do
        Thread.new { logger&.info('Broker: TERM Signal has been received') }
        threads.each do |thread|
          thread.thread_variable_set(:terminate, true)
        end
        Thread.new { logger&.info('Broker: Terminate variable for subscription threads set') }
      end

      subscriptions.each do |subscription|
        threads << Thread.new do
          subscriptions.listen(subscription)
        end
      end
      threads.each(&:join) if wait
    end

    private

    attr_reader :connection, :logger
    attr_accessor :threads

    def initialize(connection:)
      @connection = connection
      @threads = []
      @logger = EventStoreClient.config.logger
    end
  end
end
