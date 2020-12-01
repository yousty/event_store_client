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
          class Create
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
                  continuous: {
                    name: name,
                    track_emitted_streams: false
                  },
                }

              request = EventStore::Client::Projections::CreateReq.new(options: options)
              client.create(request)
              Success()
            rescue ::GRPC::Unknown => e
              Failure(:conflict) if e.message.include?('Conflict')
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
