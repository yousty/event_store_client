# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Projections
        class Create < Command
          def call(name, streams, options: {})
            data =
              <<~STRING
                fromStreams(#{streams})
                .when({
                  $any: function(s,e) {
                    linkTo("#{name}", e)
                  }
                })
              STRING


            res = connection.call(
              :post,
              "/projections/continuous?name=#{name}&type=js&enabled=yes&emit=true&trackemittedstreams=true", # rubocop:disable Metrics/LineLength
              body: data,
              headers: {}
            )

            (200...300).cover?(res.status) ? Success() : Failure(res)
          end
        end
      end
    end
  end
end
