# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/projections_pb.rb'
require 'event_store_client/adapters/grpc/generated/projections_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module Projections
        class Update < Command
          use_request EventStore::Client::Projections::UpdateReq
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
                name: name,
                emit_enabled: true
              }
            service.update(request.new(options: options), metadata: metadata)
            Success()
          rescue ::GRPC::AlreadyExists
            Failure(:conflict)
          end
        end
      end
    end
  end
end
