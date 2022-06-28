### HTTP adapter

This adapter targets the EventstoreDB version `>= "20.*"

### Configuration

As by default EventStoreClient uses gRPC adapter, to switch to http you need to configure it first.
Place the snippet below in your initializer or when you boot your application.

```ruby
EventStoreClient.configure do |config|
  config.adapter_type = :http
end
```
