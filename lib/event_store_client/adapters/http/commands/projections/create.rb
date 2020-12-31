# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Projections
        class Create < Command
          def call(name, streams)
            data =
              <<~STRING
                fromStreams(#{streams})
                .when({
                  $any: function(s,e) {
                    linkTo("#{name}", e)
                  }
                })
              STRING

            connection.call(
              :post,
              "/projections/continuous?name=#{name}&type=js&enabled=yes&emit=true&trackemittedstreams=true", # rubocop:disable Metrics/LineLength
              body: data,
              headers: {}
            )
          end
        end
      end
    end
  end
end
