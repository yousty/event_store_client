# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Client
    include Configuration

    NoCallMethodOnSubscriber = Class.new(StandardError)
    WrongExpectedEventVersion = Class.new(StandardError)

    def publish(stream:, events:, expected_version: nil)
      connection.append_to_stream(stream, events, expected_version: expected_version)
    rescue HTTP::Client::WrongExpectedEventVersion => e
      raise WrongExpectedEventVersion.new(e.message)
    end

    def read(stream, direction: 'forwards', start: 0, all: false, resolve_links: true)
      if all
        connection.read_all_from_stream(
          stream, start: start, resolve_links: resolve_links
        )
      else
        connection.read(
          stream, start: start, direction: direction, resolve_links: resolve_links
        )
      end
    end

    # TODO
    def subscribe(subscriber, to: [])
      raise NoCallMethodOnSubscriber unless subscriber.respond_to?(:call)
      subscription = @subscriptions.create(subscriber, to)
      case config.adapter
      when :api
        poll
      when :grpc
        listen
      end
    end

    def listen(wait: false)
      broker.call(@subscriptions, wait: wait)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def link_to(stream:, events:, expected_version: nil)
      raise ArgumentError if !stream || stream == ''
      raise ArgumentError if events.nil? || (events.is_a?(Array) && events.empty?)
      connection.link_to(stream, events, expected_version: expected_version)
      true
    rescue HTTP::Client::WrongExpectedEventVersion => e
      raise WrongExpectedEventVersion.new(e.message)
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
