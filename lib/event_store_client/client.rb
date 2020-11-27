# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Client
    NoCallMethodOnSubscriber = Class.new(StandardError)
    WrongExpectedEventVersion = Class.new(StandardError)

    def publish(stream:, events:, expected_version: nil)
      connection.append_to_stream(stream, events, expected_version: expected_version)
    rescue StoreAdapter::Api::Client::WrongExpectedEventVersion => e
      raise WrongExpectedEventVersion.new(e.message)
    end

    def read(stream, direction: 'forward', start: 0, all: false, resolve_links: true)
      if all
        connection.read_all_from_stream(
          stream, start: start, direction: direction, resolve_links: resolve_links
        )
      else
        connection.read(
          stream, start: start, direction: direction, resolve_links: resolve_links
        )
      end
    end

    def subscribe(subscriber, to: [], polling: true)
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      @subscriptions.create(subscriber, to)
      poll if polling
    end

    def poll(interval: 5)
      return if @polling_started
      @polling_started = true
      thread1 = Thread.new do
        loop do
          create_pid_file
          Thread.handle_interrupt(Interrupt => :never) do
            begin # rubocop:disable Style/RedundantBegin
              Thread.handle_interrupt(Interrupt => :immediate) do
                broker.call(subscriptions)
              end
            rescue Exception => e # rubocop:disable Lint/RescueException
              # When the thread had been interrupted or broker.call returned an error
              sleep(interval) # wait for events to be processed
              delete_pid_file
              error_handler&.call(e)
            ensure
              # this code is run always
              Thread.stop
            end
          end
        end
      end
      thread2 = Thread.new do
        loop do
          sleep 1
          break unless thread1.alive?
          thread1.run
        end
      end
      @threads = [thread1, thread2]
      nil
    end

    def stop_polling
      return if @threads.none?
      @threads.each(&:kill)
      @polling_started = false
      nil
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def link_to(stream:, events:, expected_version: nil)
      raise ArgumentError if !stream || stream == ''
      raise ArgumentError if events.nil? || (events.is_a?(Array) && events.empty?)
      connection.link_to(stream, events, expected_version: expected_version)
    rescue StoreAdapter::Api::Client::WrongExpectedEventVersion => e
      raise WrongExpectedEventVersion.new(e.message)
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    attr_accessor :connection, :service_name

    private

    attr_reader :subscriptions, :broker, :error_handler

    def config
      EventStoreClient::Configuration.instance
    end

    def initialize
      @threads = []
      @connection ||= config.adapter
      @error_handler ||= config.error_handler
      @service_name ||= 'default'
      @broker ||= Broker.new(connection: connection)
      @subscriptions ||= Subscriptions.new(connection: connection, service: config.service_name)
    end

    def create_pid_file
      Dir.mkdir('tmp') unless File.exist?('tmp')
      File.open(config.pid_path, 'w') { |file| file.write(Process.pid) }
    end

    def delete_pid_file
      File.delete(config.pid_path) if File.exist?(config.pid_path)
    end
  end
end
