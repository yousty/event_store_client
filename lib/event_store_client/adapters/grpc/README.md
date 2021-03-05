### GRPC adapter

This adapter targets the EventstoreDB version `>= "20.*"

### Configuration

As by default EventStoreClient uses GRPC adapter. No need to configure anything if you want to use it,
however to set it explicitly, place the snippet below in your initializer or when you boot your application.

```ruby
require 'event_store_client/adapters/grpc'

EventStoreClient.configure do |config|
  config.adapter = :grpc
end
```
