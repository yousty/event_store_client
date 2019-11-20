# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Client
    NoCallMethodOnSubscriber = Class.new(StandardError)

    def publish(stream:, events:, expected_version: nil)
      connection.publish(stream: stream, events: events, expected_version: expected_version)
    end

    def read(stream, direction: 'forward')
      connection.read(stream, direction: direction)
    end

    def subscribe(subscriber, to: [], pooling: true)
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      @subscriptions.create(subscriber, to)
      pool if pooling
    end

    def pool(interval: 5)
      # TODO: add graceful shutdown to finish processing events.
      return if @pooling_started
      @pooling_started = true
      thread1 = Thread.new { loop { broker.call(subscriptions); Thread.stop } }
      thread2 = Thread.new do
        loop { sleep interval; break unless thread1.alive?; thread1.run }
      end
      @threads = [thread1, thread2]
      nil
    end

    def stop_pooling
      return if @threads.none?
      @threads.each do |thread|
        thread.kill
      end
      @pooling_started = false
      nil
    end

    attr_accessor :connection, :service_name

    private

    attr_reader :subscriptions, :broker

    def config
      EventStoreClient::Configuration.instance
    end

    def initialize
      @threads = []
      @connection = Connection.new
      @service_name ||= 'default'
      @broker ||= Broker.new(connection: connection)
      @subscriptions ||= Subscriptions.new(connection: connection, service: config.service_name)
    end
  end
end
