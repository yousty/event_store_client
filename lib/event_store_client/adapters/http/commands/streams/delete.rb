# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Streams
        class Delete < Command
          def call(stream_name, options: {})
            connection.call(:delete, "/streams/#{stream_name}", body: {})
            Success()
          end
        end
      end
    end
  end
end
