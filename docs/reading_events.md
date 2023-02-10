# Reading Events

## Reading from a stream

The simplest way to read a stream forwards is to supply a stream name.

```ruby
EventStoreClient.client.read('some-stream')
# => [#<EventStoreClient::DeserializedEvent 0x1>, #<EventStoreClient::DeserializedEvent 0x1>]
```

### Request options customization

You can provide a block to the `#read` method. Request options will be yielded right before the request, allowing you to set advanced options:

```ruby
EventStoreClient.client.read('some-stream') do |opts|
  opts.control_option = EventStore::Client::Streams::ReadReq::Options::ControlOption.new(
    compatibility: 1
  )
end
```

### max_count

You can provide the `:max_count` option. This option determines how much records to return in a response:

```ruby
EventStoreClient.client.read('some-stream', options: { max_count: 1000 })
```

### resolve_link_tos

When using projections to create new events you can set whether the generated events are pointers to existing events. Setting this value to `true` tells EventStoreDB to return the event as well as the event linking to it.

```ruby
EventStoreClient.client.read('some-stream', options: { resolve_link_tos: true })
```

### from_revision

You can define from which revision number you would like to start to read events:

```ruby
EventStoreClient.client.read('some-stream', options: { from_revision: 2 })
```

Acceptable values are: number, `:start` and `:end`

### direction

As well as being able to read a stream forwards you can also go backwards. This can be achieved by providing the `:direction` option:

```ruby
EventStoreClient.client.read('some-stream', options: { direction: 'Backwards', from_revision: :end })
```

## Checking if stream exists

In case a stream with given name does not exist - `EventStoreClient::StreamNotFoundError` error will be raised:

```ruby
begin
  EventStoreClient.client.read('non-existing-stream')
rescue EventStoreClient::StreamNotFoundError => e
  puts e.message # => Stream "non-existing-stream" does not exist.
  puts e.stream_name # => "non-existing-stream"
end
```

## Reading from the $all stream

Simply supply `"$all"` as the stream name in `#read`:

```ruby
EventStoreClient.client.read('$all')
```

The only difference in reading from `$all` vs reading from specific stream is that you should provide `:from_position` option instead `:from_revision` in order to define a position from which to read:

```ruby
EventStoreClient.client.read('$all', options: { from_position: :start })
EventStoreClient.client.read('$all', options: { from_position: :end, direction: 'Backwards' })
EventStoreClient.client.read('$all', options: { from_position: { commit_position: 9023, prepare_position: 9023 } })
```

## Result deserialization

If you would like to skip deserialization of the `#read` result, you should use the `:skip_deserialization` argument. This way you will receive the result from EventStore DB as is, including system events, etc:

```ruby
EventStoreClient.client.read('some-stream', skip_deserialization: true)
# => [<EventStore::Client::Streams::ReadResp ...>]
```

## Filtering

The filtering feature is only available for the `$all` stream.

Retrieve events from streams with name starting with `some-stream`:

```ruby
events =
  EventStoreClient.client.read('$all', options: { filter: { stream_identifier: { prefix: ['some-stream'] } } })
events.each do |event|
# iterate through events
end
```

Retrieve events with name starting with `some-event`:

```ruby
events =
  EventStoreClient.client.read('$all', options: { event_type: { prefix: ['some-event'] } })
events.each do |event|
  # iterate through events
end
```

Retrieving events from stream `some-stream-1` and `some-stream-2`:

```ruby
events =
  EventStoreClient.client.read('$all', options: { filter: { stream_identifier: { prefix: ['some-stream-1', 'some-stream-2'] } } })
events.each do |event|
  # iterate through events
end
```

## Pagination

You can use `#read_paginated`, the ready-to-go implementation of pagination which returns an array of result pages:

```ruby
EventStoreClient.client.read_paginated('some-stream').each do |events|
  events.each do |event|
    # iterate through events
  end
end

EventStoreClient.client.read_paginated('$all').each do |events|
  events.each do |event|
    # iterate through events
  end
end
```

### Paginating backward reads

Just supply a call with `:direction` option and with `:from_position`/`:from_revision` option(depending on what stream you read from):

```ruby
EventStoreClient.client.read_paginated('some-stream', options: { direction: 'Backwards', from_revision: :end }).each do |events|
  events.each do |event|
    # iterate through events
  end
end

EventStoreClient.client.read_paginated('$all', options: { direction: 'Backwards', from_position: :end }).each do |events|
  events.each do |event|
    # iterate through events
  end
end
```

Note: for some reason when paginating the `$all` stream, EventStoreDB returns duplicate records from page to page (first event of `page N` = last event of `page N - 1`).
## User credentials

You can provide user credentials to be used to read the data as follows. This will override the default credentials set on the connection.

```ruby
EventStoreClient.client.read('some-stream', credentials: { username: 'admin', password: 'changeit' })
```
