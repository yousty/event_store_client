# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class Member
        include Extensions::OptionsExtension

        option(:host) # String
        option(:port) # Integer
        option(:active) # boolean
        option(:instance_id) # string
        option(:state) # symbol
        option(:failed_endpoint) { false } # boolean
      end
    end
  end
end
