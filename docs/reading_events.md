# Reading events

## Reading from a stream

The simplest way to read a stream forwards is to supply a stream name.

```ruby
EventStoreClient.client.read('some-stream')
# => Success([#<EventStoreClient::DeserializedEvent 0x1>, #<EventStoreClient::DeserializedEvent 0x1>])
```

This will return either `Dry::Monads::Success` with the list of events attached or `Dry::Monads::Failure` with an error. You can handle the result in next way:

```ruby
result = EventStoreClient.client.read('some-stream')
if result.success?
  result.success.each do |event|
    # do something with an event
  end
end
```

### Request options customization

You can provide a block to the `#read` method. Request options will be yielded right before the request, thus, allowing you to set advanced options for your request:

```ruby
EventStoreClient.client.read('some-stream') do |opts|
  opts.control_option = EventStore::Client::Streams::ReadReq::Options::ControlOption.new(
    compatibility: 1
  )  
end
```

### max_count

You can provide `:max_count` option. This option determines how much records to return in a response

```ruby
EventStoreClient.client.read('some-stream', options: { max_count: 1000 })
```

### resolve_link_tos

When using projections to create new events you can set whether the generated events are pointers to existing events. Setting this value to `true` tells EventStoreDB to return the event as well as the event linking to it.

```ruby
EventStoreClient.client.read('some-stream', options: { resolve_link_tos: true })
```

### from_revision

You can define from with revision number you would like to start to read events:

```ruby
EventStoreClient.client.read('some-stream', options: { from_revision: 2 })
```

Acceptable values are: number, `:start` and `:end`

### direction

As well as being able to read a stream forwards you can also go backwards. This can be achieved by providing `:direction` option:

```ruby
EventStoreClient.client.read('some-stream', options: { direction: 'Backwards', from_revision: :end })
```

## Checking if the stream exists

In case if a stream by given name does not exist, `Dry::Monads::Failure` will be returned with `:stream_not_found` value:

```ruby
result = EventStoreClient.client.read('non-existing-stream')
# => Failure(:stream_not_found)
result.failure?
# => true
result.failure
# => :stream_not_found
```

## Reading from the $all stream

Simply supply pass `"$all"` value to `#read` method:

```ruby
EventStoreClient.client.read('$all')
```

The only difference in reading from `$all` vs reading from specific stream is that you should provide `:from_position` option instead `:from_revision` in order to define a position from which to read:

```ruby
EventStoreClient.client.read('$all', options: { from_position: :start })
EventStoreClient.client.read('$all', options: { from_position: { commit_position: 9023, prepare_position: 9023 } })
```

## Result deserialization

If you would like to skip deserialization of `#read` result, you should use `:skip_deserialization` argument. This way you will the result from EventStore DB as is, including system events, etc:

```ruby
EventStoreClient.client.read('some-stream', skip_deserialization: true)
```

## Filtering

Filtering feature is only available for `$all` stream.

Retrieving events from streams that start from `some-stream`:

```ruby
result = 
  EventStoreClient.client.read('$all', options: { filter: { stream_identifier: { prefix: ['some-stream'] } } })
if result.success?
  result.success.each do |e|
    # iterate through events
  end
end
```

Retrieving events that start from `some-event` from all streams:

```ruby
result = 
  EventStoreClient.client.read('$all', options: { event_type: { prefix: ['some-event'] } })
if result.success?
  result.success.each do |e|
    # iterate through events
  end
end
```

Retrieving events from `some-stream-1` and `some-stream-2` streams:

```ruby
result = 
  EventStoreClient.client.read('$all', options: { filter: { stream_identifier: { prefix: ['some-stream-1', 'some-stream-2'] } } })
if result.success?
  result.success.each do |e|
    # iterate through events
  end
end
```

## Pagination

You can use ready-to-go implementation of pagination:

```ruby
EventStoreClient.client.read_paginated('some-stream').each do |result|
  if result.success?
    result.each do |event|
      # do something with event
    end
  end
end

EventStoreClient.client.read_paginated('$all').each do |result|
  if result.success?
    result.each do |event|
      # do something with event
    end
  end
end
```

### Paginating backward reads

Just supply a call with `:direction` option and with `:from_position`/`:from_revision` option(depending on what stream you read from):

```ruby
EventStoreClient.client.read_paginated('some-stream', options: { direction: 'Backwards', from_revision: :end }).each do |result|
  if result.success?
    result.each do |event|
      # do something with event
    end
  end
end

EventStoreClient.client.read_paginated('$all', options: { direction: 'Backwards', from_position: :end }).each do |result|
  if result.success?
    result.each do |event|
      # do something with event
    end
  end
end
```

Note: for some reason when paginating `$all` stream - EventStoreDB return duplicated records from page to page(first event of `page N` is a last event of `page N - 1`). So, please take this into account when paginating `$all` stream.

## User credentials

You can provide user credentials to be used to read the data as follows. This will override the default credentials set on the connection.

```ruby
EventStoreClient.client.read('some-stream', credentials: { username: 'admin', password: 'changeit' })
```
