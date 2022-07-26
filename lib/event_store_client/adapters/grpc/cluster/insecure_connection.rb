# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class InsecureConnection < Connection
        # @param stub_class GRPC request stub class. E.g. EventStore::Cluster::Gossip::Service::Stub
        # @return instance of the given stub_class class
        def call(stub_class)
          i = ::GRPC::ClientInterceptor.new
          # def i.request_response(request: nil, call: nil, method: nil, metadata: nil)
          #   p ""
          #   yield
          # end
          stub_class.new(
            "#{host}:#{port}",
            :this_channel_is_insecure
          )
        end
      end
    end
  end
end
