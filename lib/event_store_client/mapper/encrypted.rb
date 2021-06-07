# frozen_string_literal: true

require 'event_store_client/encryption_metadata'
require 'event_store_client/data_encryptor'
require 'event_store_client/data_decryptor'

module EventStoreClient
  module Mapper
    ##
    # Transforms given event's data and encrypts/decrypts selected subset of data
    # based on encryption schema stored in the event itself.

    class Encrypted
      MissingEncryptionKey = Class.new(StandardError)

      ##
      # Encrypts the given event's subset of data.
      # Accepts specific event class instance with:
      # * +#data+ - hash with non-encrypted values.
      # * encryption_schema - hash with information which data to encrypt and
      #   which key should be used as an identifier.
      # *Returns*: General +Event+ instance with encrypted data

      def serialize(event)
        encryption_schema = (
          event.class.respond_to?(:encryption_schema) &&
          event.class.encryption_schema
        )
        encryptor = EventStoreClient::DataEncryptor.new(
          data: event.data,
          schema: encryption_schema,
          repository: key_repository
        )
        encryptor.call
        EventStoreClient::Event.new(
          data: serializer.serialize(encryptor.encrypted_data),
          metadata: serializer.serialize(
            event.metadata.merge(encryption: encryptor.encryption_metadata)
          ),
          type: event.class.to_s
        )
      end

      ##
      # Decrypts the given event's subset of data.
      # General +Event+ instance with encrypted data
      # * +#data+ - hash with encrypted values.
      # * encryption_metadata - hash with information which data to encrypt and
      #   which key should be used as an identifier.
      # *Returns*: Specific event class with all data decrypted

      def deserialize(event, skip_decryption: false)
        metadata = serializer.deserialize(event.metadata)
        encryption_schema = serializer.deserialize(event.metadata)['encryption']

        decrypted_data =
          if skip_decryption
            serializer.deserialize(event.data)
          else
            EventStoreClient::DataDecryptor.new(
              data: serializer.deserialize(event.data),
              schema: encryption_schema,
              repository: key_repository
            ).call
          end

        event_class =
          begin
            Object.const_get(event.type)
          rescue NameError
            EventStoreClient::DeserializedEvent
          end

        event_class.new(
          id: event.id,
          type: event.type,
          title: event.title,
          data: decrypted_data,
          metadata: metadata
        )
      end

      private

      attr_reader :key_repository, :serializer

      ##
      # Initializes the mapper with required dependencies. Accepts:
      # * +key_repoistory+ - repository stored encryption keys. Passed down to the +DataEncryptor+
      # * +serializer+ - object used to serialize data. By default JSON serializer is used.
      def initialize(key_repository, serializer: Serializer::Json)
        @key_repository = key_repository
        @serializer = serializer
      end
    end
  end
end
