# frozen_string_literal: true

module EventStoreClient
  class EncryptionMetadata
    def call
      return {} unless schema

      {
        key: schema[:key].call(data),
        attributes: schema[:attributes].map(&:to_sym)
      }
    end

    private

    attr_reader :data, :schema

    def initialize(data:, schema:)
      @data = data.transform_keys(&:to_sym)
      @schema = schema
    end
  end
end
