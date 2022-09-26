# @title Deleting streams

# Deleting streams

## Soft deleting streams

When you read a soft deleted stream, the read returns `:stream_not_found` or 404 result. After deleting the stream, you are able to append to it again, continuing from where it left off.

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
