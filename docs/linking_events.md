# Linking events

## Linking single event

To create a link on an existing event, you need to have a stream name where you want to link that event to and you need to have an event, fetched from the database:

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened" }
)

stream_name_1 = 'some-stream-1'
stream_name_2 = 'some-stream-2'
EventStoreClient.client.append_to_stream(stream_name_1, event)
# Get persisted event
event = EventStoreClient.client.read(stream_name_1).success.first
# Link event from first stream into second stream
result = EventStoreClient.client.link_to(stream_name_2, event)
if result.success? # Event was successfully linked
else # event was not linked, result.failure? => true
end
```

The linked event can later be fetched by providing the `:resolve_link_tos` option when reading from the stream:

```ruby
EventStoreClient.client.read('some-stream-2', options: { resolve_link_tos: true }).success
```

If you don't provide the `:resolve_link_tos` option, the "linked" event will be returned instead of the original one.

## Linking multiple events

You can provide an array of events to link to the target stream:

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

events =
  3.times.map do
    SomethingHappened.new(
      id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened" }
    )
  end

stream_name_1 = 'some-stream-1'
stream_name_2 = 'some-stream-2'
events.each do |event|
  EventStoreClient.client.append_to_stream(stream_name_1, event)
end
# Get persisted events
events = EventStoreClient.client.read(stream_name_1).success
# Link events from first stream into second stream one by one
results = EventStoreClient.client.link_to(stream_name_2, events)
results.each do |result|
  if result.success? # Event was successfully linked
  else # event was not linked, result.failure? => true
  end
end
```

## Handling concurrency

When linking events to a stream you can supply a stream state or stream revision. Your client can use this to tell EventStoreDB what state or version you expect the stream to be in when you append. If the stream isn't in that state then an exception will be raised.

For example if we try and link two records expecting both times that the stream doesn't exist we will get an exception on the second:

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event1 = SomethingHappened.new(
  type: 'some-event', data: {},
)

event2 = SomethingHappened.new(
  type: 'some-event', data: {},
)

stream_name_1 = "some-stream-1$#{SecureRandom.uuid}"
stream_name_2 = "some-stream-2$#{SecureRandom.uuid}"

EventStoreClient.client.append_to_stream(stream_name_1, [event1, event2])
events = EventStoreClient.client.read(stream_name_1).success

results = EventStoreClient.client.link_to(stream_name_2, events, options: { expected_revision: :no_stream })
results[0].success? # => true
results[1].success? # => false because second request tries to link the event with `:no_stream` expected revision
```

There are three available stream states:

- `:any`
- `:no_stream`
- `:stream_exists`

This check can be used to implement optimistic concurrency. When you retrieve a stream from EventStoreDB, you take note of the current version number, then when you save it back you can determine if somebody else has modified the record in the meantime.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

stream_name_1 = "some-stream-1$#{SecureRandom.uuid}"
stream_name_2 = "some-stream-2$#{SecureRandom.uuid}"
event1 = SomethingHappened.new(
  type: 'some-event', data: {}
)
event2 = SomethingHappened.new(
  type: 'some-event', data: {}
)

# Pre-create some events
EventStoreClient.client.append_to_stream(stream_name_1, event1)
EventStoreClient.client.append_to_stream(stream_name_2, event2)
# Load events from DB
event1 = EventStoreClient.client.read(stream_name_1).success.first
event2 = EventStoreClient.client.read(stream_name_2).success.first
# Get the revision number of latest event
revision = EventStoreClient.client.read(stream_name_2).success.last.stream_revision
# Expected revision matches => will succeed
EventStoreClient.client.link_to(stream_name_2, event1, options: { expected_revision: revision })
# Will fail with revisions mismatch error
EventStoreClient.client.link_to(stream_name_2, event2, options: { expected_revision: revision })
```

## User credentials

You can provide user credentials to be used to append the data as follows. This will override the default credentials set on the connection.

```ruby
class SomethingHappened < EventStoreClient::DeserializedEvent
end

event = SomethingHappened.new(
  id: SecureRandom.uuid, type: 'some-event', data: { user_id: SecureRandom.uuid, title: "Something happened" }
)

stream_name_1 = 'some-stream-1'
stream_name_2 = 'some-stream-2'
EventStoreClient.client.append_to_stream(stream_name_1, event)
# Get persisted event
event = EventStoreClient.client.read(stream_name_1).success.first
# Link event from first stream into second stream
result = EventStoreClient.client.link_to(stream_name_2, event, credentials: { username: 'admin', password: 'changeit' })
```
