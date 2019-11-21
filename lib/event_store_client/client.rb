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
      return if @pooling_started
      @pooling_started = true
      thread1 = Thread.new do
        loop do
          create_pid_file
          Thread.handle_interrupt(Interrupt => :never) {
            begin
              Thread.handle_interrupt(Interrupt => :immediate) {
                broker.call(subscriptions)
              }
            rescue Exception => e
              # When the thread had been interrupted or broker.call returned an error
              sleep(interval) # wait for events to be processed
              delete_pid_file
              error_handler.call(e) if error_handler
            ensure
              # this code is run always
              Thread.stop
            end
          }
        end
      end
      thread2 = Thread.new do
        loop { sleep 1; break unless thread1.alive?; thread1.run }
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

    attr_reader :subscriptions, :broker, :error_handler

    def config
      EventStoreClient::Configuration.instance
    end

    def initialize
      @threads = []
      @connection ||= Connection.new
      @error_handler ||= config.error_handler
      @service_name ||= 'default'
      @broker ||= Broker.new(connection: connection)
      @subscriptions ||= Subscriptions.new(connection: connection, service: config.service_name)
    end

    def create_pid_file
      return unless File.exists?(config.pid_path)
      File.open(config.pid_path, 'w') { |file| file.write(SecureRandom.uuid) }
    end

    def delete_pid_file
      File.delete(config.pid_path)
    end
  end
end
