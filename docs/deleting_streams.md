# @title Deleting streams

# Deleting streams

## Soft deleting streams

When you read a soft deleted stream, the read raises `EventStoreClient::StreamNotFoundError` error. After deleting the stream, you are able to append to it again, continuing from where it left off.

```ruby
EventStoreClient.client.delete_stream('some-stream')
```

## Hard deleting streams

A hard delete of a stream is permanent. You cannot append to the stream or recreate it. As such, you should generally soft delete streams unless you have a specific need to permanently delete the stream.

```ruby
EventStoreClient.client.hard_delete_stream('some-stream')
```

## User credentials

You can provide user credentials to be used to delete the stream as follows. This will override the default credentials set on the connection.

```ruby
EventStoreClient.client.delete_stream('some-stream', credentials: { username: 'admin', password: 'changeit' })
```

## Possible errors during stream deletion

If you try to delete non-existing stream, or if you provided `:expected_revision` option with a value which doesn't match current stream's state - `EventStoreClient::StreamDeletionError` error will be raised:

```ruby
begin
  EventStoreClient.client.delete_stream('non-existing-stream')
rescue => e
  puts e.message
end
```
