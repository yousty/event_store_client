# frozen_string_literal: true

require 'event_store_client/configuration'

module EventStoreClient
  class DataDecryptor
    include Configuration

    KeyNotFoundError = Class.new(StandardError)

    def call
      return encrypted_data if encryption_metadata.empty?

      decrypt_attributes(
        key: find_key(encryption_metadata['key']),
        data: encrypted_data,
        attributes: encryption_metadata['attributes']
      )
    end

    private

    attr_reader :key_repository, :encryption_metadata, :encrypted_data

    def initialize(data:, schema:, repository:)
      @encrypted_data = deep_dup(data).transform_keys!(&:to_s)
      @key_repository = repository
      @encryption_metadata = schema&.transform_keys(&:to_s) || {}
    end

    def decrypt_attributes(key:, data:, attributes: {}) # rubocop:disable Lint/UnusedMethodArgument
      return data unless key

      res = key_repository.decrypt(key: key, message: data['es_encrypted'])
      return data if res.failure?

      decrypted_text = res.value!
      decrypted = JSON.parse(decrypted_text.attributes[:message]).transform_keys(&:to_s)
      decrypted.each { |k, value| data[k] = value if data.key?(k) }
      data.delete('es_encrypted')
      data
    end

    def deep_dup(hash)
      return hash unless hash.instance_of?(Hash)
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
          nil
        end

      key
    end
  end
end
