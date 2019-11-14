# EventStoreClient

An easy-to use API client for connecting ruby applications with https://eventstore.org/

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'event_store_client'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install event_store_client
```

## Usage

1. Download Event Store From https://eventstore.org/downloads/ or docker

` docker pull eventstore/eventstore`

2. Run the Event Store server

`docker run --name eventstore -it -p 2113:2113 -p 1113:1113 eventstore/eventstore`

3. Set Basic HTTP auth enviornment variables #below are defaults
  - export EVENT_STORE_USER=admin
  - export EVENT_STORE_PASSWORD=changeit

Ref: https://eventstore.org/docs/http-api/security

4. Checkout connection

```
# define your events
class SomethingHappened < Dry::Struct
  attribute :data, EventStoreClient::Types::Strict::Hash
  attribute :metadata, EventStoreClient::Types::Strict::Hash
end

event = SomethingHappened.new(
  data: { user_id: SecureRandom.uuid, title: "Something happened" },
  metadata: {}
)

connection = EventStoreClient::Connection.new
connection.publish(stream: 'newstream', event: event)
events = connection.read('newstream')
connection.subscribe('$et-SomethingHappened', name: 'default')
events = connection.consume_feed('$et-SomethingHappened', 'default')

class DummyHandler
  def self.call(event)
    puts "Handled #{event.class.name}"
  end
end
connection = EventStoreClient::Connection.new
event_store = EventStoreClient::EventStore.new do |es|
  es.connection = connection
end
event_store.subscribe(DummyHandler, to: [SomethingHappened])
event_store.poll

connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)

event_store.stop_polling
```

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
