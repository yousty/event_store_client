# frozen_string_literal: true

require 'grpc'
require 'event_store_client/store_adapter/grpc/generated/projections_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/projections_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/command'

module EventStoreClient
  module StoreAdapter
    module GRPC
      module Commands
        module Projections
          class Create < Command
            use_request EventStore::Client::Projections::CreateReq
            use_service EventStore::Client::Projections::Projections::Stub

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

              service.create(request.new(options: options))
              Success()
            rescue ::GRPC::Unknown => e
              Failure(:conflict) if e.message.include?('Conflict')
            end
          end
        end
      end
    end
  end
end
