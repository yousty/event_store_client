### HTTP adapter

This adapter targets the EventstoreDB version `>= "5.*"

For detailed docs about the http protocol see [EventStoreDB Http Documentation](https://developers.eventstore.com/server/5.0.8/http-api/)

### Configuration

As by default EventStoreClient uses gRPC adapter, to switch to http you need to configure it first.
Place the snippet below in your initializer or when you boot your application.

```ruby
EventStoreClient.configure do |config|
  config.adapter = :api
end
```
