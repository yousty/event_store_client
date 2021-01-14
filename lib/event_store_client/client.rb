# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Client
    include Configuration

    NoCallMethodOnSubscriber = Class.new(StandardError)
    WrongExpectedEventVersion = Class.new(StandardError)

    def publish(stream:, events:, options: {})
      connection.append_to_stream(stream, events, options: options)
    rescue HTTP::Client::WrongExpectedEventVersion => e
      raise WrongExpectedEventVersion.new(e.message)
    end

    def read(stream, options: {})
      if options[:all]
        connection.read_all_from_stream(stream, options: options)
      else
        connection.read(stream, options: options)
      end
    end

    def subscribe(subscriber, to: [])
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      @subscriptions.create(subscriber, to)
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

    attr_accessor :connection, :service_name

    private

    attr_reader :subscriptions, :broker, :error_handler

    def initialize
      @threads = []
      @connection ||= EventStoreClient.adapter
      @error_handler ||= config.error_handler
      @service_name ||= 'default'
      @broker ||= Broker.new(connection: connection)
      @subscriptions ||= Subscriptions.new(connection: connection, service: config.service_name)
    end
  end
end
