![Run tests](https://github.com/yousty/event_store_client/workflows/Run%20tests/badge.svg?branch=master&event=push)
[![Gem Version](https://badge.fury.io/rb/event_store_client.svg)](https://badge.fury.io/rb/event_store_client)

# EventStoreClient

An easy-to use API client for connecting ruby applications with [EventStoreDB](https://eventstore.com/)

## Supported adapters

- [GRPC](https://github.com/yousty/event_store_client/tree/master/lib/event_store_client/adapters/grpc/README.md) - default
- [HTTP](https://github.com/yousty/event_store_client/tree/master/lib/event_store_client/adapters/http/README.md) - Deprecated
- InMemory - for testing

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'event_store_client', '~> 1.0'
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

Before you start, make sure you are connecting to a running EventStoreDB instance. For a detailed guide see:
[EventStoreServerSetup](https://github.com/yousty/event_store_client/blob/master/docs/eventstore_server_setup.md)

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


```ruby

require 'event_store_client'
require "event_store_client/adapters/grpc"

EventStoreClient.configure do |config|
  config.eventstore_url = ENV['EVENTSTORE_URL']
  config.eventstore_user = ENV['EVENTSTORE_USER']
  config.eventstore_password = ENV['EVENTSTORE_PASSWORD']
  config.verify_ssl = false # remove this line if your server does have the host verified
end

event_store = EventStoreClient::Client.new

event_store.subscribe(
  DummyHandler.new,
  to: [SomethingHappened]
)

event_store.listen
```

## Features

## Basic Usage

The main interface allows for actions listed below which is enough for basic useage.
The actual adapter allows for more actions. Contributions as always welcome!

```ruby
# Publishing to a stream
event_store.publish(stream: 'newstream', events: [event])

# Reading from a stream
events = event_store.read('newstream').value!

# Reading all events from a stream
events = event_store.read('newstream', options: { all: true }).value! #default 'false'

# Linking existing events to a new stream
event_store.link_to(stream_name, events)

# Subscribing to events
event_store.subscribe(DummyHandler.new, to: [SomethingHappened])

# Listening to new events for all registered subscriptions
event_store.listen

# In the new terminal session publish some events
events = (1..10).map { event }
event_store.publish(stream: 'newstream', events: events)
# .... wait a little bit ... Your handler should be called for every single event you publish
```

### Extended usage

You can get access to more features by calling the adapter directly, for example:

```
event_store.connection.delete_stream(stream)
event_store.connection.tombstone_stream(stream)
```

See the adapters method list for the possible usage.

- [HTTP](https://github.com/yousty/event_store_client/blob/master/lib/event_store_client/adapters/http/client.rb)
- [GRPC](https://github.com/yousty/event_store_client/blob/master/lib/event_store_client/adapters/grpc/client.rb)

### Configuration

There are several configuration options you can pass to customize your client's instance.
All the config options can be passed the same way:

```ruby
EventStoreClient.configure do |config|
  config.adapter_type = :grpc
end
```

| name        | value           | default   | description |
|:-------------:|:-------------:|:-----:|:-------------:|
| adapter      | `:grpc`, `:http` or `:in_memory` | `:grpc` | different ways to connect with an event_store_db. The in_memory is a mock server useful for testing |
| verify_ssl   | Boolean      | true | Useful for self-signed certificates (Kubernetes, local development) |
| error_handler | Any callable ruby object | EvenStoreClient::ErrorHandler | You can pass a custom error handler for reacting on event_handler errors.|
| eventstore_url| String| 'http://localhost:2113'| An url for the server instance|
| user| String| 'admin' | a user used to connect the application with the server|
| password| String| 'changeit'| a password used to connect the application with the server|
| per_page| Integer| 20 | a batch size for events subscriptions |
| service_name| String| 'default' | a prefix (namespace) added to the subscriptions names|
| mapper| `Mapper::Default` or `Mapper::Encrypted`| `Mapper::Default.new` | an engine used to parse events.

## Event Mappers

At the moment we offer two types of mappers:

- default
- encrypted

### Default Mapper

This is used out of the box. It just translates the EventClass defined in your application to
Event parsable by event_store and the other way around.

### Encrypted Mapper

This is implemented to match GDPR requirements. It allows you to encrypt any event using your
encryption_key repository. For the detailed guide see the: [Encrypting Events](https://github.com/yousty/event_store_client/blob/master/docs/encrypting_events.md).

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

For running the client in the dev mode, see: [Development Guide](https://github.com/yousty/event_store_client/blob/master/docs/eventstore_server_setup.md)

### Re-generating GRPC files from Proto

If you need to re-generate GRPC files from [Proto](https://github.com/EventStore/EventStore/tree/master/src/Protos/Grpc) files - there is a tool to do it. Just run next command:

```shell
bin/rebuild_protos
```

### Running tests

You will have to install Docker first. It is needed to run EventStore DB. You can run EventStore DB with next command:

```shell
docker-compose -f docker-compose.local.yml up
```

### Publishing new version

1. Push commit with updated `version.rb` file to the `release` branch. The new version will be automatically pushed to [rubygems](https://rubygems.org).
2. Create release on github including change log.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
