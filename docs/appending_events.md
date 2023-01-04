# @title Appending events

# Append your first event

## Append your first event

The simplest way to append an event to EventStoreDB is to create an `EventStoreClient::DeserializedEvent` object and call the `#append_to_stream` method.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened" }
)

begin
  EventStoreClient.client.append_to_stream('some-stream', event) 
  # => EventStore::Client::Streams::AppendResp
rescue EventStoreClient::WrongExpectedVersionError => e
  puts e.message  
end
```

## Appending multiple events

You can pass an array of events to the `#append_to_stream` method. This way events will be appended one-by-one. On each iteration `revision` will be incremented by 1. In case if any of requests fails - all further append requests will be canceled.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event1 = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened 1" }
)
event2 = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened 2" }
)

begin
  EventStoreClient.client.append_to_stream('some-stream', [event1, event2]) 
  # => Array<EventStore::Client::Streams::AppendResp>
rescue EventStoreClient::WrongExpectedVersionError => e
  puts e.message
  puts e.caused_by # event which caused the error
end
```

## Working with EventStoreClient::DeserializedEvent

When appending events to EventStoreDB they must first all be wrapped in an `EventStoreClient::DeserializedEvent` object. This allows you to specify the content of the event and the type of event.

A sample of creating an event:

```ruby
EventStoreClient::DeserializedEvent.new(
  # ID of event. Optional. If omitted, its value is generated using `SecureRandom.uuid`
  id: SecureRandom.uuid,
  # Event name. Optional. If omitted, its value will be generated using `self.class.to_s`
  type: 'some-event-name',
  # Event data. Optional. Will default to `{}` (empty hash) if omitted
  data: { foo: :bar },
  # Optional. You can put here any value which is not supposed to be present in data.
  custom_metadata: {}
)
```

### Duplicated event id

If two events with the same id are appended to the same stream in quick succession EventStoreDB will only append one copy of the event to the stream.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: {},
)
EventStoreClient.client.append_to_stream('some-stream', event)
# Attempt to append the same event again. Will return the same result as for previous call
EventStoreClient.client.append_to_stream('some-stream', event)
```


## Handling concurrency

When appending events to a stream you can supply a stream state or stream revision. Your client can use this to tell EventStoreDB what state or version you expect the stream to be in when you append. If the stream isn't in that state then an exception will be thrown.

For example if we try to and append two records expecting both times that the stream doesn't exist we will get an exception on the second:

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event1 = SomethingHappened.new(
  type: 'some-event', data: {},
)

event2 = SomethingHappened.new(
  type: 'some-event', data: {},
)

stream_name = "some-stream$#{SecureRandom.uuid}"

EventStoreClient.client.append_to_stream(stream_name, event1, options: { expected_revision: :no_stream })

EventStoreClient.client.append_to_stream(stream_name, event2, options: { expected_revision: :no_stream })
```

There are three available stream states:

- `:any`
- `:no_stream`
- `:stream_exists`

This check can be used to implement optimistic concurrency. When you retrieve a stream from EventStoreDB, you take note of the current version number, then when you save it back you can determine if somebody else has modified the record in the meantime.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

stream_name = "some-stream$#{SecureRandom.uuid}"
event1 = SomethingHappened.new(
  type: 'some-event', data: {}
)
event2 = SomethingHappened.new(
  type: 'some-event', data: {}
)

# Pre-populate stream with some event
EventStoreClient.client.append_to_stream(stream_name, event1)
# Get the revision number of latest event
revision = EventStoreClient.client.read(stream_name).last.stream_revision
# Expected revision matches => will succeed
EventStoreClient.client.append_to_stream(stream_name, event2, options: { expected_revision: revision })
# Will fail with revisions mismatch error
EventStoreClient.client.append_to_stream(stream_name, event2, options: { expected_revision: revision })
```

## User credentials

You can provide user credentials to be used to append the data as follows. This will override the default credentials set on the connection.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened" }
)

EventStoreClient.client.append_to_stream('some-stream', event, credentials: { username: 'admin', password: 'changeit' })
```
