# frozen_string_literal: true

module EventStoreClient
  module Serializer
    module Json
      # @param data [String, Hash]
      # @return [Hash]
      def self.deserialize(data)
        return data if data.is_a?(Hash)

        result = JSON.parse(data)
        return result if result.is_a?(Hash)

        { 'message' => result }
      rescue JSON::ParserError
        { 'message' => data }
      end

      # @param data [String, Object]
      # @return [String]
      def self.serialize(data)
        return data if data.is_a?(String)

        JSON.generate(data)
      end
    end
  end
end
