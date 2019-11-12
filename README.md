# EventStoreClient

An easy-to use API client for connecting ruby applications with https://eventstore.org/

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'event_store_client'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install event_store_client
```

## Usage

```
# define your events
class SomethingHappened < Dry::Struct
  attribute :data, EventStoreClient::Types::Strict::Hash
  attribute :metadata, EventStoreClient::Types::Strict::Hash
end

event = SomethingHappened.new(
  data: { user_id: SecureRandom.uuid, title: "Something happened" },
  metadata: {}
)

connection = EventStoreClient::Connection.new
connection.publish(stream: 'dummystream', event: event)
connection.read('dummystream')
```



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
