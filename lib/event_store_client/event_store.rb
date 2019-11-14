# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class EventStore
    NoCallMethodOnSubscriber = Class.new(StandardError)

    def subscribe(subscriber, to: [])
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      @subscriptions.create(subscriber, to)
    end

    def poll(interval: 5)
      thread1 = Thread.new { loop { broker.call(subscriptions); Thread.stop } }
      thread2 = Thread.new do
        loop { sleep interval; break unless thread1.alive?; thread1.run }
      end
      @threads = [thread1, thread2]
      nil
    end

    def stop_polling
      @threads.each do |thread|
        thread.kill
      end
      nil
    end

    attr_accessor :connection, :service_name

    private

    attr_reader :subscriptions, :broker

    def initialize
      yield(self) if block_given?

      @connection ||= Connection.new
      @service_name ||= 'default'
      @broker ||= Broker.new(connection: connection)
      @subscriptions ||= Subscriptions.new(connection: connection, service: service_name)
    end
  end
end
