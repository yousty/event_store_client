# frozen_string_literal: true

module EventStoreClient
  class DataDecryptor
    KeyNotFoundError = Class.new(StandardError)

    def call
      return encrypted_data if encryption_metadata.empty?

      decrypt_attributes(
        key: find_key(encryption_metadata[:key]),
        data: decrypted_data,
        attributes: encryption_metadata[:attributes]
      )
    end

    attr_reader :decrypted_data, :encryption_metadata

    private

    attr_reader :key_repository

    def initialize(data:, schema:, repository:)
      @decrypted_data = deep_dup(data).transform_keys!(&:to_sym)
      @key_repository = repository
      @encryption_metadata = schema.transform_keys(&:to_sym)
    end

    def decrypt_attributes(key:, data:, attributes:)
      decrypted_text = key_repository.decrypt(
        key_id: key.id, text: data[:es_encrypted], cipher: key.cipher, iv: key.iv
      )
      decrypted = JSON.parse(decrypted_text).transform_keys(&:to_sym)
      decrypted.each { |key, value| data[key] = value if data.key?(key) }
      data.delete(:es_encrypted)
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
          key_repository.find(identifier)
        rescue StandardError => e
          nil
        end
      raise KeyNotFoundError unless key

      key
    end
  end
end
