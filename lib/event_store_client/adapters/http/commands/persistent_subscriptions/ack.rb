# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module PersistentSubscriptions
        class Ack < Command
          def call(url)
            connection.call(:post, url)
          end
        end
      end
    end
  end
end
