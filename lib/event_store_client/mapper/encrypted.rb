# frozen_string_literal: true

require 'event_store_client/encryption_metadata'
require 'event_store_client/data_encryptor'

module EventStoreClient
  module Mapper
    class Encrypted
      MissingEncryptionKey = Class.new(StandardError)

      def serialize(event)
        encryption_schema = (
          event.class.respond_to?(:encryption_schema) &&
          event.class.encryption_schema
        )
        encryptor = DataEncryptor.new(
          data: event.data,
          schema: encryption_schema,
          repository: key_repository
        )
        encryptor.call
        Event.new(
          data: serializer.serialize(encryptor.encrypted_data),
          metadata: serializer.serialize(
            event.metadata.merge(encryption: encryptor.encryption_metadata)
          ),
          type: event.class.to_s
        )
      end

      def deserialize(_event); end

      private

      attr_reader :key_repository, :serializer

      def initialize(key_repository, serializer: Serializer::Json)
        @key_repository         = key_repository
        @serializer             = serializer
      end
    end
  end
end
