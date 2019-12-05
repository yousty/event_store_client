# frozen_string_literal: true

module EventStoreClient
  class DataEncryptor
    def call
      return encrypted_data unless encryption_metadata
      encryption_metadata.each do |key_id, val|
        key = key_repository.find(key_id) || key_repository.create(key_id)
        val[:iv] ||= key.iv
        val[:attributes].each do |att|
          encrypted_data[att] = encrypt_attribute(
            key, encrypted_data.fetch(att)
          )
        end
      end
      encrypted_data
    end

    attr_reader :encrypted_data, :encryption_metadata

    private

    attr_reader :key_repository

    def initialize(data:, schema:, repository:)
      @encrypted_data = deep_dup(data)
      @key_repository = repository
      @encryption_metadata = EncryptionMetadata.new(data: data, schema: schema).call
    end

    def encrypt_attribute(key, text)
      key_repository.encrypt(
        key_id: key.id, text: text, cipher: key.cipher, iv: key.iv
      )
    end

    def deep_dup(hash)
      dupl = hash.dup
      dupl.each { |k, v| dupl[k] = v.instance_of?(Hash) ? deep_dup(v) : v }
      dupl
    end
  end
end
