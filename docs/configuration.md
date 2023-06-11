# Configuration

Configuration options:

| name                 | value                                                                                | default value                                                                                                                     | description                                                                                                                                                                                                                                           |
|----------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| eventstore_url      | String                                                                               | `'esdb://localhost:2113'`                                                                                                         | Connection string. See description of possible values below.                                                                                                                                                                                          |
| per_page             | Integer                                                                              | `20`                                                                                                                              | Number of events to return in one response.                                                                                                                                                                                                           |
| mapper               | `EventStoreClient::Mapper::Default.new` or `EventStoreClient::Mapper::Encrypted.new` | `EventStoreClient::Mapper::Default.new`                                                                                           | An object that is responsible for serialization / deserialization and encryption / decryption of events.                                                                                                                                              |
| default_event_class  | `DeserializedEvent` or any class, inherited from it                                  | `DeserializedEvent`                                                                                                               | This class will be used during the deserialization process when deserializer fails to resolve an event's class from response.                                                                                                                         |
| logger               | `Logger`                                                                             | `nil`                                                                                                                             | A logger that would log messages from `event_store_client` and `grpc` gems.                                                                                                                                                                           |
| skip_deserialization | Boolean                                                                              | `false`                                                                                                                           | Whether to skip event deserialization using the given `mapper` setting. If you set it to `true` decryption will be skipped as well. It is useful when you want to defer deserialization and handle it later by yourself.                              |
| skip_decryption      | Boolean                                                                              | `false`                                                                                                                           | Whether to skip decrypting encrypted event payloads.                                                                                                                                                                                                  |
| channel_args      | Hash                                                                                 | `{ 'grpc.min_reconnect_backoff_ms' => 100, 'grpc.max_reconnect_backoff_ms' => 100, 'grpc.initial_reconnect_backoff_ms' => 100 }` | GRPC-specific connection options. This hash will be passed into the `:channel_args` argument of a Stub class of your request. More GRPC options can be found [here](https://github.com/grpc/grpc/blob/master/include/grpc/impl/grpc_types.h). |

## A note about channel_args option

When defining the custom value of this option - the default value will be reverse-merged into it. So, for example, if you would like to set `grpc.min_reconnect_backoff_ms` like so:

```ruby
EventStoreClient.configure do |config|
  config.channel_args = { 'grpc.min_reconnect_backoff_ms' => 200 }
end
```

the resulting `channel_args` value will be

```ruby
{
  "grpc.min_reconnect_backoff_ms" => 200,
  "grpc.max_reconnect_backoff_ms" => 100,
  "grpc.initial_reconnect_backoff_ms" => 100
}
```

This behaviour is intentional. So, if you want to override them all - you should do it explicitly. Example:

```ruby
EventStoreClient.configure do |config|
  config.channel_args = {
    'grpc.min_reconnect_backoff_ms' => 500,
    'grpc.max_reconnect_backoff_ms' => 500,
    'grpc.initial_reconnect_backoff_ms' => 500
  }
end
```

It could be useful when you have high ping to your EventStore DB server.

Besides, there is an option which you can't change - `grpc.enable_retries`. It always defaults to `0`. This is because `event_store_client` implements its own retry functional.

## Connection string

Connection string allows you to provide connection options and a set of nodes of your cluster to connect to.

Structure:

```
protocol://[username:password@]node1[,node2,node3,...,nodeN]/?connectionOptions
```

### Protocol

There are two possible values:

- `esdb`. Currently no effect.
- `esdb+discover`. `+discover` tells the client that your cluster is setup as [DNS discovery](https://developers.eventstore.com/server/v20.10/cluster.html#cluster-with-dns). This means that the client will perform a lookup of cluster members of the first node you provided in the connection string.

Examples:
```
esdb://localhost:2113
esdb+discover://localhost:2113
```

### Credentials

You may provide a username and password to be used to connect to the EventStore DB. Only secure connections will use those credentials. Only credentials defined with first node will be used.

Examples:

```
esdb://some-admin:some-password@localhost:2113
esdb://some-admin:some-password@localhost:2113,localhost:2114
```

### Nodes

At least one node should be defined in the connection string in order for the client to work properly. You may define as much nodes as you want. However, the behavior of the client may change depending on how many nodes you provided and whether you set the `+discover` flag.

Possible behaviours:

- One node is provided. E.g. `esdb://localhost:2113`. The client assumes this setup is a standalone server - no cluster discovery will be done.
- One node and `+discover` flag is provided. E.g. `esdb+discover://localhost:2113`. The client assumes this setup is a cluster with DNS discover setup - cluster discovery will be done.
- Two or more nodes are provided. E.g. `esdb://localhost:2113,localhost:2114,localhost:2115`. The client assumes this setup is a nodes cluster setup - cluster discovery will be done. If discovery of a node fails, the next node in the list will be picked, and so forth, in round-robin manner, until max discovery attempts number is reached.

If you provide more than one node and set `+discover` flag - only the first node will be considered.

### Connection options

Connection options allows you to adjust parameters such as timeout, security, etc.

Possible options:

| name                 | value                                           | default value | description                                                                                                                                                                                                                                            |
|----------------------|-------------------------------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tls                  | Boolean                                         | `true`        | Whether to use a secure connection                                                                                                                                                                                                                       |
| tlsVerifyCert        | Boolean                                         | `false`       | Whether to verify a certificate                                                                                                                                                                                                                        |
| tlsCAFile            | String                                          | `nil`         | A path to a certificate file (e.g. `ca.crt`). If you set the `tls` option to `true`, but didn't provide this option, the client  will try to automatically retrieve an X.509 certificate from the nodes.                                                   |
| gossipTimeout        | Integer                                         | `200`         | Milliseconds. Discovery request timeout. Only useful when there are several nodes or when `+discover` flag is set.                                                                                                                                      |
| discoverInterval     | Integer                                         | `100`         | Milliseconds. Interval between discovery attempts. Only useful when there are several nodes or when `+discover` flag is set.                                                                                                                            |
| maxDiscoverAttempts  | Integer                                         | `10`          | Max attempts before giving up to find a suitable cluster member. Only useful when there are several nodes or when the `+discover` flag is set.                                                                                                             |
| caLookupInterval     | Integer                                         | `100`         | Milliseconds. Interval between X.509 certificate lookup attempts. This option is useful when you set the`tls` option to true, but you didn't provide the `tlsCAFile` option. In this case the certificate will be retrieved using the Net::HTTP#peer_cert method. |
| caLookupAttempts     | Integer                                         | `3`           | Number of attempts for X.509 certificate lookup. This option is useful when you set the `tls` option to true, but you didn't provide the `tlsCAFile` option. In this case the certificate will be retrieved using Net::HTTP#peer_cert method.                |
| nodePreference       | `"leader"`, `"follower"` or `"readOnlyReplica"` | `"leader"`    | Set which state of cluster members is preferred. Only useful if you provided the `+discover` flag or defined several nodes in the connection string.                                                                                                           |
| timeout              | Integer, `nil`                                  | `nil`         | Milliseconds. Defines how long to wait for a response before throwing an error. This option doesn't apply to subscriptions. If set to `nil` - `event_store_client` will be waiting for a response forever (if there is a connection at all).                |
| grpcRetryAttempts    | Integer                                         | `3`           | Number of times to retry GRPC requests. Does not apply to discovery requests. Final number of requests in cases of error will be initial request + grpcRetryAttempts.                                                                                  |
| grpcRetryInterval    | Integer                                         | `100`         | Milliseconds. Delay between GRPC requests. retries.                                                                                                                                                                                                      |
| throwOnAppendFailure | Boolean                                         | `true`        | Defines if append requests should immediately raise an error. If set to `false`, request will be retried in case of a server error.                                                                                                                       |

Examples:

```
esdb://localhost:2113/?tls=false
esdb+discover://localhost:2113/?grpcRetryAttempts=3&grpcRetryInterval=300&discoverInterval=200
esdb://localhost:2113,localhost:2114,localhost:2115/?gossipTimeout=500&maxDiscoverAttempts=3
```

### Multiple configurations

`event_store_client` provides a possibility to configure as much connections as you want. To do so, you have to name your configuration, and later provide that name to `EventStoreClient` client.

Setup your configs:
```ruby
EventStoreClient.configure(name: :es_db_1) do |config|
  # adjust your config here
  config.eventstore_url = 'esdb://localhost:2113'
end
EventStoreClient.configure(name: :es_db_2) do |config|
  # adjust your second config here
  config.eventstore_url = 'esdb://localhost:2114'
end
```

Tell `EventStoreClient` which config you want to use:

```ruby
client1 = EventStoreClient.client(config_name: :es_db_1)
client2 = EventStoreClient.client(config_name: :es_db_2)
# Read from $all stream using :es_db_1 config
client1.read('$all')
# Read from $all stream using :es_db_2 config
client2.read('$all')
```

#### Default config

If you only have one config - you don't have to bother naming it or passing a config name to the client when performing any operations. You can configure it as usual.

Setup your default config:
```ruby
EventStoreClient.configure do |config|
  # config goes here
  config.eventstore_url = 'esdb://localhost:2113'
end
```

Use it:

```ruby
client = EventStoreClient.client
# Read from $all stream using your default config
client.read('$all')
```
