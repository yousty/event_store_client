# frozen_string_literal: true


module EventStoreClient
  class EncryptionMetadata
    def call
      return {} unless schema

      schema.each_with_object({}) do |(attr_name, key_proc), acc|
        key_identifier = key_proc.call(data)
        acc[key_identifier] ||= { attributes: [] }
        acc[key_identifier][:attributes] |= [attr_name]
        acc
      end
    end

    private

    attr_reader :data, :schema

    def initialize(data:, schema:)
      @data = data
      @schema = schema
    end
  end
end
