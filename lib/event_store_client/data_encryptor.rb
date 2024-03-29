# frozen_string_literal: true

module EventStoreClient
  class DataEncryptor
    def call
      return encrypted_data if encryption_metadata.empty?

      key_id = encryption_metadata[:key]
      res = key_repository.find(key_id)
      res = res.failure? ? key_repository.create(key_id) : res
      key = res.value!

      encryption_metadata[:iv] = key.attributes[:iv]
      encrypt_attributes(
        key: key,
        data: encrypted_data,
        attributes: encryption_metadata[:attributes].map(&:to_s)
      )
    end

    attr_reader :encrypted_data, :encryption_metadata

    private

    attr_reader :key_repository

    def initialize(data:, schema:, repository:)
      @encrypted_data = deep_dup(data).transform_keys!(&:to_s)
      @key_repository = repository
      @encryption_metadata = EncryptionMetadata.new(data: data, schema: schema).call
    end

    def encrypt_attributes(key:, data:, attributes:)
      text = JSON.generate(data.select { |hash_key, _value| attributes.include?(hash_key.to_s) })
      encrypted = key_repository.encrypt(key: key, message: text).value!
      attributes.each { |att| data[att.to_s] = 'es_encrypted' if data.key?(att.to_s) }
      data['es_encrypted'] = encrypted.attributes[:message]
      data
    end

    def deep_dup(hash)
      return hash unless hash.instance_of?(Hash)

      dupl = hash.dup
      dupl.each { |k, v| dupl[k] = v.instance_of?(Hash) ? deep_dup(v) : v }
      dupl
    end
  end
end
