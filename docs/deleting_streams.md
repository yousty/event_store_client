# Deleting streams

## Hard deleting streams

A hard delete of a stream is permanent. You cannot append to the stream or recreate it. As such, you should generally soft delete streams unless you have a specific need to permanently delete the stream.

```ruby
EventStoreClient.client.hard_delete_stream('some-stream')
```
