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
  def self.call(event)
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

**Changing reading direction

```ruby
events = client.read('newstream', direction: 'backward') #default 'forward'
```

### Subscribing to events

```ruby
client.subscribe(DummyHandler, to: [SomethingHappened])

# now try to publish several events
10.times { client.publish(stream: 'newstream', events: [event]) }

You can also publish multiple events at once

events = (1..10).map { event }
client.publish(stream: 'newstream', events: events)

# .... wait a little bit ... Your handler should be called for every single event you publish
```

### Stop polling for new events

```ruby
client.stop_polling
```

### Linking existing events to the streem

Event to be linked properly has to coantians original event id.
Real events could be mixed with linked events in the same stream.

```ruby
exisiting_event1 = client.read('newstream').last
client.link_to(stream: 'anotherstream', events: [exisiting_event1, ...])
```

When you read from stream where links are placed. By default Event Store Client always resolve links for you returning the event that points to the link. You can use the ES-ResolveLinkTos: false HTTP header during readin stream to tell Event Store Client to return you the actual link and to not resolve it.
More info: [ES-ResolveLinkTos](https://eventstore.org/docs/http-api/optional-http-headers/resolve-linkto/index.html?tabs=tabid-1%2Ctabid-3).

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
