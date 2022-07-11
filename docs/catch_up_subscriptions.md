# Catch-up subscriptions

Subscriptions allow you to subscribe to a stream and receive notifications about new events added to the stream.

You provide an event handler and an optional starting point to the subscription. The handler is called for each event from the starting point onward.

If events already exist, the handler will be called for each event one by one until it reaches the end of the stream. From there, the server will notify the handler whenever a new event appears.

## Subscribing from the start

When you need to process all the events in the store, including historical events, you'd need to subscribe from the beginning. You can either subscribe to receive events from a single stream, or subscribe to `$all` if you need to process all events in the database.

### Subscribing to a stream

The simplest stream subscription looks like the following:

```ruby
handler = proc do |result| 
  if result.success?
    event = result.success # retrieve a result
    # ... do something with event
  else # result.failure?
    puts result.failure # prints error
  end
end
EventStoreClient.client.subscribe_to_stream('some-stream', handler: handler)
```

The provided handler will be called for every event in the stream.

### Subscribing to $all

Subscribing to `$all` is much the same as subscribing to a single stream. The handler will be called for every event appended after the starting position.

```ruby
handler = proc do |result| 
  if result.success?
    event = result.success # retrieve a result
    # ... do something with event
  else # result.failure?
    puts result.failure # prints error
  end
end
EventStoreClient.client.subscribe_to_all(handler: handler)
```

## Subscribing from a specific position

The previous examples will subscribe to the stream from the beginning. This will end up calling the handler for every event in the stream and then wait for new events after that.

Both the stream and $all subscriptions accept a starting position if you want to read from a specific point onward. If events already exist at the position you subscribe to, they will be read on the server side and sent to the subscription.

Once caught up, the sever will push any new events received on the streams to the client. There is no difference between catching up and live on the client side.

### Subscribing to a stream

To subscribe to a stream from a specific position, you need to provide a _stream position_. This can be `:start`, `:end` or integer position.

The following subscribes to the stream `some-stream` at position `20`, this means that events `21` and onward will be handled:

```ruby
EventStoreClient.client.subscribe_to_stream('some-stream', handler: proc { |res| }, options: { from_revision: 20 })
```

### Subscribing to $all

Subscribing to the `$all` stream is much like subscribing to a regular stream. The only difference is how you need to specify the stream position. For the `$all` stream, you have to provide `:from_position` hash instead, which consists of two integers - `:commit_position` and `:prepare_position` positions. The `:from_position` value can accept `:start` and `:end` values as well.

The corresponding `$all` subscription will subscribe from the event after the one at commit position `1056` and prepare position `1056`.

Please note that this position will need to be a legitimate position in `$all`.

```ruby
EventStoreClient.client.subscribe_to_all(handler: proc { |res| }, options: { from_position: { commit_position: 1056, prepare_position: 1056 } })
```

## Subscribing to a stream for live updates

You can subscribe to a stream to get live updates by subscribing to the end of the stream:

```ruby
EventStoreClient.client.subscribe_to_stream('some-stream', handler: proc { |res| }, options: { from_revision: :end })
```

And the same works with `$all` :

```ruby
EventStoreClient.client.subscribe_to_all(handler: proc { |res| }, options: { from_position: :end })
```

This won't read through the history of the stream, but will rather notify the handler when a new event appears in the respective stream.

Keep in mind that when you subscribe to a stream from a certain position - you will also get live updates after your subscription catches up (processes all the historical events).

## Resolving link-to's

Link-to events point to events in other streams in EventStoreDB. These are generally created by projections such as the `$by_event_type` projection which links events of the same event type into the same stream. This makes it easier to look up all events of a certain type.

When reading a stream you can specify whether to resolve link-to's or not. By default, link-to events are not resolved. You can change this behaviour by setting the `resolve_link_tos` option to `true`:

```ruby
EventStoreClient.client.subscribe_to_stream('$et-myEventType', handler: proc { |res| }, options: { resolve_link_tos: true })
```

## Handling subscription drops

An application, which hosts the subscription, can go offline for a period of time for different reasons. It could be a crash, infrastructure failure, or a new version deployment. As you rarely would want to reprocess all the events again, you'd need to store the current position of the subscription somewhere, and then use it to restore the subscription from the point where it dropped off:

```ruby
checkpoint = :start
handler = proc do |result|
  if result.success?
    event = result.success
    handle_event(result.success)
    checkpoint = event.stream_revision    
  else
    # do something in case of error
  end
end

EventStoreClient.client.subscribe_to_stream('some-stream', handler: handler, options: { from_revision: checkpoint })
```

When subscribed to `$all` you want to keep the position of the event in the `$all` stream. As mentioned previously, the `$all` stream position consists of two integers (prepare and commit positions), not one:

```ruby
checkpoint = :start
handler = proc do |result|
  if result.success?
    event = result.success
    handle_event(result.success)
    checkpoint = { prepare_position: event.prepare_position, commit_position: event.commit_position }
  else
    # do something in case of error
  end
end

EventStoreClient.client.subscribe_to_all(handler: handler, options: { from_position: checkpoint })
```

## User credentials

The user creating a subscription must have read access to the stream it's subscribing to, and only admin users may subscribe to `$all` or create filtered subscriptions.

The code below shows how you can provide user credentials for a subscription. When you specify subscription credentials explicitly, it will override the default credentials set for the client. If you don't specify any credentials, the client will use the credentials specified for the client, if you specified those.

```ruby
EventStoreClient.client.subscribe_to_stream('some-stream', handler: proc { |res| }, credentials: { username: 'admin', password: 'changeit' })
```

## Server-side filtering

