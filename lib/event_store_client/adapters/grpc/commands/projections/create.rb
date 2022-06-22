# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/projections_pb'
require 'event_store_client/adapters/grpc/generated/projections_services_pb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
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
                  track_emitted_streams: true
                }
              }

            res = Try do
              service.create(request.new(options: options), metadata: metadata)
            end

            res.error? ? res.to_result : Success()
          rescue ::GRPC::Unknown => e
            Failure(:conflict) if e.message.include?('Conflict')
          end
        end
      end
    end
  end
end
