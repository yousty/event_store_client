# frozen_string_literal: true

require 'securerandom'
require_relative './dummy_event'
require_relative './event_handlers'

class AdaptersTestRun
  def call
    publish_events(count: 100, batch: false)
    publish_events(count: 10, batch: true)
    read_events_from_stream(all: false)
    read_events_from_stream(all: true)
    subscribe(FooHandler, [SomethingHappened])
    subscribe(BarHandler, [SomethingHappened])
    listen(FooHandler, [SomethingHappened])
    listen(BarHandler, [SomethingHappened])
    # delete_stream(stream, hard: false)
    # delete_stream(stream, hard: true)
  end

  def publish_events(count: 10, batch: false)
    puts "\n#{__method__} #{count} events (batch: #{batch}"

    events = Array.new(count) do
      SomethingHappened.new(
        data: { user_id: SecureRandom.uuid, title: 'Something happened' }
      )
    end
    return client.append_to_stream(stream, events) if batch

    events.map { |event| client.append_to_stream(stream, [event]) }
  end

  def delete_stream(stream, hard: false)
    puts "\n#{__method__} #{stream} (hard: #{hard}"
    return client.delete_stream(stream) unless hard

    client.tombstone_stream(stream)
  end

  def read_events_from_stream(all: false)
    puts "\n#{__method__} (all: #{all}\n"
    res =
      if all
        client.read_all_from_stream(stream)
      else
        client.read(stream)
      end
    pp "READ result: Successs:#{res.success?}, length: #{res.value!.length}"
    pp res.value!.first
    puts "\n"
  end

  def subscribe(handler, event_types)
    puts "\n#{__method__} #{handler} to:  #{event_types}\n"

    subscription = EventStoreClient::Subscription.new(
      handler, event_types: event_types, service: 'test-service'
    )
    client.subscribe_to_stream(subscription)
  end

  def listen(handler, event_types)
    subscription = EventStoreClient::Subscription.new(
      handler, event_types: event_types, service: 'test-service'
    )
    client.listen(subscription, options: { interval: 1, count: 10 }) do |event|
      subscription.subscriber.call(event)
    end
  end

  private

  attr_reader :client, :stream

  def initialize(client, stream: 'defaultstream')
    @client = client
    @stream = stream
  end
end
