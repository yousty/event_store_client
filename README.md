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

### EventStore engine setup

1. Download Event Store From https://eventstore.org/downloads/ or docker

` docker pull eventstore/eventstore`

2. Run the Event Store server

`docker run --name eventstore -it -p 2113:2113 -p 1113:1113 eventstore/eventstore`

3. Set Basic HTTP auth enviornment variables #below are defaults
  - export EVENT_STORE_USER=admin
  - export EVENT_STORE_PASSWORD=changeit

Ref: https://eventstore.org/docs/http-api/security

4. Login to admin panel http://localhost:2113 and enable Projections for Event-Types

### Configure EventStoreClient

Before you start, add this to the `initializer` or to the top of your script:

`EventStoreClient.configure`

### Create Dummy event and dummy Handler

To test out the behavior, you'll need a sample event and handler to work with:

```ruby
# Sample Event using dry-struct (recommended)
require 'dry-struct'
class SomethingHappened < Dry::Struct
  attribute :data, EventStoreClient::Types::Strict::Hash
  attribute :metadata, EventStoreClient::Types::Strict::Hash
end

# Sample Event without types check (not recommended)

class SomethingHappened < Dry::Struct
  attr_reader :data, :metadata

  private

  def initialize(data: {}, metadata: {})
    @data = data
    @metadata = metadata
  end
end

event = SomethingHappened.new(
  data: { user_id: SecureRandom.uuid, title: "Something happened" },
  metadata: {}
)
```

Now create a handler. It can be anything, which responds to a `call` method
with an event being passed as an argument.

```ruby
class DummyHandler
  def self.call(event)
    puts "Handled #{event.class.name}"
  end
end
```
## Usage

```ruby
# initialize the client
client = EventStoreClient::EventStore.new
```

### Publishing events

```ruby
client.publish(stream: 'newstream', events: [event])
```

### Reading from a stream

```ruby
events = client.read('newstream')
```

**Changing reading direction

```ruby
events = client.read('newstream', direction: 'backward') #default 'forward'
```

### Subscribing to events

# Using automatic polling

```ruby
client = EventStoreClient::EventStore.new
client.subscribe(DummyHandler, to: [SomethingHappened])
client.poll

# now try to publish several events
connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)
connection.publish(stream: 'newstream', event: event)
# .... wait a little bit ... Your handler should be called for every single event you publish
```

### Stop polling

```ruby
client.stop_polling
```

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
