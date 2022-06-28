# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'

module EventStoreClient
  module GRPC
    module Options
      module Streams
        class RevisionOption
          attr_reader :value

          # @param val [String, Integer, nil]
          def initialize(val)
            @value = resolve(val)
          end

          # @return [Boolean]
          def number?
            value&.key?(:revision)
          end

          # @return [Integer]
          def increment!
            value[:revision] += 1
          end

          private

          # @return [Hash]
          def resolve(val)
            case val
            when 'any', 'no_stream', 'stream_exists'
              { val.to_sym => EventStore::Client::Empty.new }
            when Integer
              { revision: val }
            else
              resolve('any')
            end
          end
        end
      end
    end
  end
end
