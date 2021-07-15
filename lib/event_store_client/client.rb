# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Client
    include Configuration

    NoCallMethodOnSubscriber = Class.new(StandardError)
    WrongExpectedEventVersion = Class.new(StandardError)

    def publish(stream:, events:, options: {})
      res = connection.append_to_stream(stream, events, options: options)
      raise WrongExpectedEventVersion.new(e.message) if res.failure?
      res
    end

    def read(stream, options: {})
      if options[:all]
        connection.read_all_from_stream(stream, options: options)
      else
        connection.read(stream, options: options)
      end
    end

    def subscribe(subscriber, to: [], options: {})
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      @subscriptions.create(subscriber, to, options: options)
    end

    def subscribe_to_all(subscriber, filter=nil)
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)

      @subscriptions.create_or_load(subscriber, filter: filter)
    end

    def reset_subscriptions
      return unless @subscriptions.respond_to?(:reset)

      @subscriptions.reset
    end

    def listen(wait: false)
      broker.call(@subscriptions, wait: wait)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def link_to(stream:, events:, options: {})
      raise ArgumentError if !stream || stream == ''
      raise ArgumentError if events.nil? || (events.is_a?(Array) && events.empty?)
      res = connection.link_to(stream, events, options: options)
      raise WrongExpectedEventVersion.new(e.message) if res.failure?

      res.success?
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    attr_accessor :connection

    private

    attr_reader :subscriptions, :broker, :error_handler

    def initialize
      @threads = []
      @connection = EventStoreClient.adapter
      @error_handler = config.error_handler
      @broker = Broker.new(connection: connection)
      @subscriptions = config.subscriptions_repo
      @subscriptions ||= Subscriptions.new(connection: connection, service: config.service_name)
    end
  end
end
