# frozen_string_literal: true

require 'grpc'

module EventStoreClient
  module StoreAdapter
    module GRPC
      class Connection
        include Configuration

        # Initializes the proper stub with the necessary credentials
        # to create working gRPC connection - Refer to generated grpc files
        # @return [Stub] Instance of a given `Stub` klass
        #
        def call(stub_klass)
          stub_klass.new(
            config.eventstore_url.to_s, :this_channel_is_insecure
          )
        end
      end
    end
  end
end
