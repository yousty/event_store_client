![Run tests](https://github.com/yousty/event_store_client/workflows/Run%20tests/badge.svg?branch=master&event=push)
[![Gem Version](https://badge.fury.io/rb/event_store_client.svg)](https://badge.fury.io/rb/event_store_client)

# EventStoreClient

An easy-to use GRPC API client for connecting ruby applications with [EventStoreDB](https://eventstore.com/).

## Requirements

`event_store_client` gem requires:

- ruby 2.7 or newer.
- EventstoreDB version `>= "20.*"`.

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

Before you start, make sure you are connecting to a running EventStoreDB instance. For a detailed guide see:
[EventStoreServerSetup](https://github.com/yousty/event_store_client/blob/master/docs/eventstore_server_setup.md)

See documentation chapters for the usage reference:

- [Configuration](docs/configuration.md)
- [Encrypting events](docs/encrypting_events.md)
- [Appending events](docs/appending_events.md)
- [Reading events](docs/reading_events.md)
- [Linking events](docs/linking_events.md)
- [Catch-up subscriptions](docs/catch_up_subscriptions.md)
- [Deleting streams](docs/deleting_streams.md)

## Contributing

Do you want to contribute? Welcome!

1. Fork repository
2. Create Issue
3. Create PR ;)

### Re-generating GRPC files from Proto

If you need to re-generate GRPC files from [Proto](https://github.com/EventStore/EventStore/tree/master/src/Protos/Grpc) files - there is a tool to do it. Just run next command:

```shell
bin/rebuild_protos
```

### Running tests and development console

You will have to install Docker first. It is needed to run EventStore DB. You can run EventStore DB with next command:

```shell
docker-compose -f docker-compose-cluster.yml up
```

Now you can enter dev console by running `bin/console` or run tests by running `rspec` command.

### Publishing new version

1. Push commit with updated `version.rb` file to the `release` branch. The new version will be automatically pushed to [rubygems](https://rubygems.org).
2. Create release on github including change log.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
