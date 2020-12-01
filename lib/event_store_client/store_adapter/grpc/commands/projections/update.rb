# frozen_string_literal: true

require 'dry-monads'
require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Projections
          class Update
            include Dry::Monads[:result]
            include Configuration

            def call(name, streams)
              data = <<~STRING
                fromStreams(#{streams})
                .when({
                  $any: function(s,e) {
                    linkTo("#{name}", e)
                  }
                })
              STRING

              options =
                {
                  query: data,
                  name: name,
                  emit_enabled: true
                }
              request = EventStore::Client::Projections::UpdateReq.new(options: options)
              res = client.update(request)
              Success()
            rescue ::GRPC::AlreadyExists
              Failure(:conflict)
            end
            private

            def client
              EventStore::Client::Projections::Projections::Stub.new(
                config.eventstore_url.to_s, :this_channel_is_insecure
              )
            end
          end
        end
      end
    end
  end
end
