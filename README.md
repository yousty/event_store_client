![Run tests](https://github.com/yousty/event_store_client/workflows/Run%20tests/badge.svg?branch=master&event=push)
[![Gem Version](https://badge.fury.io/rb/event_store_client.svg)](https://badge.fury.io/rb/event_store_client)

# EventStoreClient

### Broken version. Please use version 0.2.3 until the next release happen. Fixes will be applied in 0.3.0

An easy-to use API client for connecting ruby applications with https://eventstore.org/

## Supported adapters

- GRPC - default
- [HTTP](https://github.com/yousty/event_store_client/tree/master/lib/event_store_client/adapters/http/README.md) - Deprecated
- Memory - for testing

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

Before you start, make sure you have a running EventStoreDB instance on your machine

### EventStore engine setup

1. Download Event Store From https://eventstore.org/downloads/ or docker

` docker pull eventstore/eventstore`

2. Run the Event Store server

`docker run --env EVENTSTORE_INSECURE=true --name eventstore -it -p 2113:2113 -p 1113:1113 eventstore/eventstore`

4. Visit the admin panel http://localhost:2113 and enable Projections for Event-Types

### Create Dummy event and dummy Handler

To test out the behavior, you'll need a sample event and event handler to work with:

```ruby

require 'securerandom'

class SomethingHappened < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:title).value(:string)
    end
  end
end

event = SomethingHappened.new(
  data: { user_id: SecureRandom.uuid, title: "Something happened" },
)
```

Now create a handler. It can be anything, which responds to a `call` method
with an event being passed as an argument.

```ruby
class DummyHandler
  def call(event)
    puts "Handled #{event.class.name}"
  end
end
```
## Usage

```ruby
# initialize the client
client = EventStoreClient::Client.new
```

### Publishing events

```ruby
client.publish(stream: 'newstream', events: [event])
```

### Reading from a stream

```ruby
events = client.read('newstream')
```

**Changing reading direction**

```ruby
events = client.read('newstream', direction: 'backwards') #default 'forwards'
```

**Reading all events from a stream**

```ruby
events = client.read('newstream', all: true) #default 'false'
```

### Subscribing to events

```ruby
client.subscribe(DummyHandler.new, to: [SomethingHappened])

# Now In another terminal seesion try to publish several events
10.times { client.publish(stream: 'newstream', events: [event]) }

# You can also publish multiple events at once

events = (1..10).map { event }
client.publish(stream: 'newstream', events: events)

# .... wait a little bit ... Your handler should be called for every single event you publish
```

### Stop polling for new events

```ruby
client.stop_polling
```

### Configure EventStoreClient

Before you start, add this to the `initializer` or to the top of your script:

For testing, you can use the InMemory adapter. To do it you should change the configuration.

```ruby
EventStoreClient.configure do |config|
  config.adapter = EventStoreClient::InMemory.new(host: 'http://localhost', port: '2113')
end
```

## Event Mappers

At the moment we offer two types of mappers:

- default
- encrypted

### Default Mapper

This is used out of the box. It just translates the EventClass defined in your application to
Event parsable by event_store and the other way around.

### Encrypted Mapper

This is implemented to match GDPR requirements. It allows you to encrypt any event using your
encryption_key repository.

```ruby
mapper = EventStoreClient::Mapper::Encrypted.new(key_repository)
EventStoreClient.configure do |config|
  config.mapper = mapper
end
```

The Encrypted mapper uses the encryption key repository to encrypt data in your events according to the event definition.

Here is the minimal repository interface for this to work.

```ruby
class DummyRepository
  class Key
    attr_accessor :iv, :cipher, :id
    def initialize(id:, **)
      @id = id
    end
  end

  def find(user_id)
    Key.new(id: user_id)
  end

  def encrypt(*)
    'darthvader'
  end

  def decrypt(*)
    { first_name: 'Anakin', last_name: 'Skylwalker'}
  end
end
```

Now, having that, you only need to define the event encryption schema:

```ruby
class EncryptedEvent < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
      required(:profession).value(:string)
    end
  end

  def self.encryption_schema
    {
      key: ->(data) { data['user_id'] },
      attributes: %i[first_name last_name email]
    }
  end
end

event = EncryptedEvent.new(
  user_id: SecureRandom.uuid,
  first_name: 'Anakin',
  last_name: 'Skylwalker',
  profession: 'Jedi'
)
```

When you'll publish this event, in the store will be saved:

```ruby
{
  'data' => {
    'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
    'first_name' => 'encrypted',
    'last_name' => 'encrypted',
    'profession' => 'Jedi',
    'encrypted' => '2345l423lj1#$!lkj24f1'
  },
  type: 'EncryptedEvent'
  metadata: { ... }
}
```

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

### Publishing new version

1. Push commit with updated `version.rb` file to the `release` branch. The new version will be automatically pushed to [rubygems](https://rubygems.org).
2. Create release on github including change log.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
