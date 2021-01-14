# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module PersistentSubscriptions
        class Create < Command
          def call(stream_name, subscription_name, options: {})
            stats = options[:stats] || true
            start = options[:start] || 0
            retries = options[:retries] || 5

            connection.call(
              :put,
              "/subscriptions/#{stream_name}/#{subscription_name}",
              body: {
                extraStatistics: stats,
                startFrom: start,
                maxRetryCount: retries,
                resolveLinkTos: true
              },
              headers: {
                'Content-Type' => 'application/json'
              }
            )
          end
        end
      end
    end
  end
end
