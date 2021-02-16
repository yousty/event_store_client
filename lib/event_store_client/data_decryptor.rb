# frozen_string_literal: true

require 'event_store_client/configuration'

module EventStoreClient
  class DataDecryptor
    include Configuration

    KeyNotFoundError = Class.new(StandardError)

    def call
      return decrypted_data if encryption_metadata.empty?

      decrypt_attributes(
        key: find_key(encryption_metadata['key']),
        data: decrypted_data,
        attributes: encryption_metadata['attributes']
      )
    end

    attr_reader :decrypted_data, :encryption_metadata

    private

    attr_reader :key_repository

    def initialize(data:, schema:, repository:)
      @decrypted_data = deep_dup(data).transform_keys!(&:to_s)
      @key_repository = repository
      @encryption_metadata = schema&.transform_keys(&:to_s) || {}
    end

    def decrypt_attributes(key:, data:, attributes: {}) # rubocop:disable Lint/UnusedMethodArgument
      res = key_repository.decrypt(key: key, message: data['es_encrypted'])
      return data if res.failure?

      decrypted_text = res.value!
      decrypted = JSON.parse(decrypted_text.attributes[:message]).transform_keys(&:to_s)
      decrypted.each { |k, value| data[k] = value if data.key?(k) }
      data.delete('es_encrypted')
      data
    end

    def deep_dup(hash)
      dupl = hash.dup
      dupl.each { |k, v| dupl[k] = v.instance_of?(Hash) ? deep_dup(v) : v }
      dupl
    end

    def find_key(identifier)
      key =
        begin
          key_repository.find(identifier).value!
        rescue StandardError => e
          config.error_handler&.call(e)
        end
      raise KeyNotFoundError unless key

      key
    end
  end
end
