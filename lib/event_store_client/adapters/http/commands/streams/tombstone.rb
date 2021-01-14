# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Streams
        class Tombstone < Command
          def call(stream_name, options: {}) # rubocop:disable Lint/UnusedMethodArgument
            headers = { 'ES-HardDelete' => 'true' }
            connection.call(:delete, "/streams/#{stream_name}", body: {}, headers: headers)
            Success()
          end
        end
      end
    end
  end
end
