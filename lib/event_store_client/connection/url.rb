# frozen_string_literal: true

module EventStoreClient
  module Connection
    # Structured representation of connection string. You should not use it directly. If you would
    # like to parse connection string into an instance of this class - use
    # EventStoreClient::Connection::UrlParser instead.
    # @api private
    class Url
      include Extensions::OptionsExtension

      NODE_PREFERENCES = %i(Leader Follower ReadOnlyReplica).freeze
      Node = Struct.new(:host, :port)

      # This option will allow you to perform the discovery by only one host
      # https://developers.eventstore.com/server/v21.10/cluster.html#cluster-with-dns
      option(:dns_discover) { false }
      option(:username) { 'admin' }
      option(:password) { 'changeit' }
      # Whether to throw
      option(:throw_on_append_failure) { true }
      # Whether to use secure connection
      option(:tls) { true }
      # Whether to verify a certificate
      option(:tls_verify_cert) { false }
      # A path to certificate file
      option(:tls_ca_file)
      # Interval between X.509 certificate lookup attempts. This option is useful when you set tls
      # option to true, but you didn't provide tls_ca_file option. In this case the certificate
      # will be retrieved using Net::HTTP#peer_cert method.
      option(:ca_lookup_interval) { 100 } # milliseconds
      # Number of attempts of lookup of X.509 certificate
      option(:ca_lookup_attempts) { 3 }
      # Discovery request timeout. Only useful when there are several nodes or when dns_discover
      # option is true
      option(:gossip_timeout) { 200 } # milliseconds
      # Max attempts before giving up to find a suitable node. Only useful when there are several
      # nodes or when dns_discover option is true
      option(:max_discover_attempts) { 10 }
      # Interval between discover attempts
      option(:discover_interval) { 100 } # milliseconds
      # One value for both - connection and request timeouts
      option(:timeout) # milliseconds
      # During the discovery - set which state will be taken in prio during nodes look up
      option(:node_preference) { NODE_PREFERENCES.first }
      # A list of nodes to discover. It is represented as an array of
      # EventStoreClient::Connection::Url::Node instances
      option(:nodes) { Set.new }
      # Number of time to retry GRPC request. Does not apply to discover request. Final number of
      # requests in cases of error will be initial request + grpc_retry_attempts.
      option(:grpc_retry_attempts) { 3 }
      # Delay between GRPC request retries
      option(:grpc_retry_interval) { 100 } # milliseconds
    end
  end
end
