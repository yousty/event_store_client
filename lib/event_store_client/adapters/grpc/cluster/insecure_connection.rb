# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class InsecureConnection < Connection
        # @param stub_class GRPC request stub class. E.g. EventStore::Client::Gossip::Gossip::Stub
        # @return instance of the given stub_class class
        def call(stub_class)
          config.logger&.debug('Using insecure connection.')
          stub_class.new(
            "#{host}:#{port}",
            :this_channel_is_insecure,
            channel_args: config.channel_args,
            timeout: (timeout / 1000.0 if timeout)
          )
        end
      end
    end
  end
end
