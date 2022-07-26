# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'
require 'event_store_client/adapters/grpc/generated/gossip_pb'
require 'event_store_client/adapters/grpc/generated/gossip_services_pb'

module EventStoreClient
  module GRPC
    module Commands
      module Gossip
        class ClusterInfo < Command
          use_request EventStore::Client::Empty
          use_service EventStore::Client::Gossip::Gossip::Stub

          # @api private
          # @see {EventStoreClient::GRPC::Client#cluster_info}
          def call
            Success(service.read(request.new))
          end
        end
      end
    end
  end
end
