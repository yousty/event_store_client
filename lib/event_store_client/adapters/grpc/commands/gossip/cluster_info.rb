# frozen_string_literal: true

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
            retry_request { service.read(request.new, metadata: metadata) }
          end
        end
      end
    end
  end
end
