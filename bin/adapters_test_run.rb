# frozen_string_literal: true

require 'securerandom'
require_relative './dummy_event'
require_relative './event_handlers'

class AdaptersTestRun
  def call
    # publish_events(count: 100, batch: false)
    #publish_events(count: 2, batch: true)
    # publish_other_events(count: 2, batch: true)
    # subscribe_to_all
    # store.listen(wait: true)
    #read_events_from_stream(all: false)
    # read_events_from_stream(all: true)
    #subscribe(FooHandler, [SomethingHappened])
    # link_to('linkedstream')
    # subscribe(BarHandler, [SomethingHappened])
    # subscribe(ZooHandler, [SomethingHappened])
    # listen(FooHandler, [SomethingHappened])
    # listen(ZooHandler, [SomethingHappened])
    # listen(BarHandler, [SomethingHappened])
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

  def publish_other_events(count: 10, batch: false)
    puts "\n#{__method__} #{count} events (batch: #{batch}"

    events = Array.new(count) do
      SomethingElseHappened.new(
        data: { user_id: SecureRandom.uuid, title: 'Something else happened' }
      )
    end
    return client.append_to_stream(stream, events) if batch

    events.map { |event| client.append_to_stream(stream, [event]) }
  end

  def delete_stream(stream, hard: false)
    puts "\n#{__method__} #{stream} (hard: #{hard})"
    return client.delete_stream(stream) unless hard

    client.tombstone_stream(stream)
  end

  def read_events_from_stream(all: false)
    puts "\n#{__method__} (all: #{all})\n"
    res =
      if all
        client.read_all_from_stream(stream)
      else
        client.read(stream)
      end
    puts "READ result: Successs:#{res.success?}, length: #{res.value!.length}"
    puts res.value!.map(&:title).first(100)
    puts "\n"
  end

  def subscribe_to_all
    subscriber = lambda do |event|
      puts '###############'
      puts event.inspect
    end

    store.subscribe_to_all(
      subscriber,
      id: SecureRandom.uuid,
      filter: {
        event_type: { regex: '^SomethingElse.*' },
        max: 32,
        checkpointIntervalMultiplier: 1000
      }
    )
  end

  def subscribe(handler, event_types)
    puts "\n#{__method__} #{handler} to:  #{event_types}\n"
    store.subscribe(handler, to: event_types)
  end

  def listen(handler, event_types)
    subscription = store.send(:subscriptions).send(:subscriptions).first
    client.listen(subscription, options: { interval: 1, count: 10 }) do |event|
      subscription.subscriber.call(event)
    end
  end

  def link_to(stream_name, count: 10)
    events = client.read(stream, options: { count: count }).value!
    client.link_to(stream_name, events)
  end


  private

  attr_reader :client, :stream, :store

  def initialize(store, stream: 'defaultstream')
    @store = store
    @client = store.connection
    @stream = stream
  end
end
