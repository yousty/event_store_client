# Configuration

Currently `event_store_client` gem supports the one setup. Thus, e.g, you can't configure a connection to multiple _clusters_.

Configuration options:

| name                 | value                                                                                | default value                           | description                                                                                                                                                                                                                              |
|----------------------|--------------------------------------------------------------------------------------|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| event_store_url      | String                                                                               | `'esdb://localhost:2113'`               | Connection string. See description of possible values bellow.                                                                                                                                                                            |
| per_page             | Integer                                                                              | `20`                                    | Number of events to return in one response.                                                                                                                                                                                              |
| mapper               | `EventStoreClient::Mapper::Default.new` or `EventStoreClient::Mapper::Encrypted.new` | `EventStoreClient::Mapper::Default.new` | An object that is responsible for serialization/deserialization and encryption/decryption of events.                                                                                                                                     |
| default_event_class  | `DeserializedEvent` or any class, inherited from it                                  | `DeserializedEvent`                     | This class will be used during the deserialization process when deserializer fails to resolve an event's class from response                                                                                                             |
| logger               | `Logger`                                                                             | `nil`                                   | A logger that would log messages from `event_store_client` and `grpc` gems                                                                                                                                                               |
| skip_deserialization | Boolean                                                                              | `false`                                 | Whether to skip events deserialization using an object, provided in `mapper` setting. If you set it to `true` - decryption will be skipped as well. It is useful when you want to defer deserialization and handle it later by yourself. |
| skip_decryption      | Boolean                                                                              | `false`                                 | Whether to skip events decryption.                                                                                                                                                                                                       |

## Connection string

Connection string allows you to provide connection options and set of nodes of your cluster to connect to. Structure of connection string is next:

```
protocol://[username:password@]node1[,node2,node3,...,nodeN]/?connectionOptions
```

### Protocol

There are two possible values:

- `esdb`. Affects on nothing currently
- `esdb+discover`. When `+discover` flag is provided, it tells to the `event_store_client` gem that your cluster is setup as [DNS discovery](https://developers.eventstore.com/server/v20.10/cluster.html#cluster-with-dns). This means that `event_store_client` will perform lookup of cluster members of first node you provided in connection string.

Examples:
```
esdb://localhost:2113
esdb+discover://localhost:2113
```

### Credentials

You may provide username and password that will be used to connect to EventStore DB. Only secure connections will use those credentials. Only credentials, defined with first node will be used.

Examples:

```
esdb://some-admin:some-password@localhost:2113
esdb://some-admin:some-password@localhost:2113,localhost:2114
```

### Nodes

At least one node should be defined in the connection string in order `event_store_client` gem to work properly. You may define as much nodes as you want. However, the behavior of `event_store_client` gem may change depending on how many nodes you provided and whether you set `+discover` flag.

Possible behaviours:

- one node is provided. E.g. `esdb://localhost:2113`. `event_store_client` counts this setup as a standalone server - no cluster discovery will be done
- one node and `+discover` flag is provided. E.g. `esdb+discover://localhost:2113`. `event_store_client` counts this setup as a cluster with DNS discover setup - cluster discovery will be done
- two or more nodes are provided. E.g. `esdb://localhost:2113,localhost:2114,localhost:2115`. `event_store_client` counts this setup as a nodes cluster setup - cluster discovery will be done. If discover of a node fails, next node in the list will be picked, and so forth, in round-robin manner, until max discover attempts number is reached.

If you provided more than one node and set `+discover` flag - only first node will be considered.

### Connection options

Connection options allows you to adjust such parameters, as timeout, security, etc. You may find a list of options in the table bellow.

| name                 | value                                           | default value | description                                                                                                                                                                                                                                            |
|----------------------|-------------------------------------------------|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| tls                  | Boolean                                         | `true`        | Whether to use secure connection                                                                                                                                                                                                                       |
| tlsVerifyCert        | Boolean                                         | `false`       | Whether to verify a certificate                                                                                                                                                                                                                        |
| tlsCAFile            | String                                          | `nil`         | A path to certificate file(e.g. `ca.crt`). If you set `tls` option to `true`, but didn't provide this option - `event_store_client` will try to retrieve X.509 certificate from nodes automatically.                                                   |
| gossipTimeout        | Integer                                         | `200`         | Milliseconds. Discover request timeout. Only useful when there are several nodes or when `+discover` flag is set.                                                                                                                                      |
| discoverInterval     | Integer                                         | `100`         | Milliseconds. Interval between discover attempts. Only useful when there are several nodes or when `+discover` flag is set.                                                                                                                            |
| maxDiscoverAttempts  | Integer                                         | `10`          | Max attempts before giving up to find a suitable cluster member. Only useful when there are several nodes or when `+discover` flag is set.                                                                                                             |
| caLookupInterval     | Integer                                         | `100`         | Milliseconds. Interval between X.509 certificate lookup attempts. This option is useful when you set `tls` option to true, but you didn't provide `tlsCAFile` option. In this case the certificate will be retrieved using Net::HTTP#peer_cert method. |
| caLookupAttempts     | Integer                                         | `3`           | Number of attempts of lookup of X.509 certificate. This option is useful when you set `tls` option to true, but you didn't provide `tlsCAFile` option. In this case the certificate will be retrieved using Net::HTTP#peer_cert method.                |
| nodePreference       | `"leader"`, `"follower"` or `"readOnlyReplica"` | `"leader"`    | Set which state of cluster members is preferred. Only useful if you provided `+discover` flag or defined several nodes in connection string.                                                                                                           |
| timeout              | Integer, `nil`                                  | `nil`         | Milliseconds. Defines how long to wait for response before throwing an error. This option doesn't apply to subscriptions. If set to `nil` - `event_store_client` will be waiting for response forever(if there is a connection at all).                |
| grpcRetryAttempts    | Integer                                         | `3`           | Number of times to retry GRPC request. Does not apply to discover requests. Final number of requests in cases of error will be - initial request + grpcRetryAttempts.                                                                                  |
| grpcRetryInterval    | Integer                                         | `100`         | Milliseconds. Delay between GRPC request retries.                                                                                                                                                                                                      |
| throwOnAppendFailure | Boolean                                         | `true`        | Defines if append request should raise error immediately. If set to `false`, in case of server error - request will be retried.                                                                                                                        |