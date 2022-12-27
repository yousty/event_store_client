# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize, Layout/LineLength, Style/IfUnlessModifier

require 'event_store_client/encryption_metadata'
require 'event_store_client/data_encryptor'
require 'event_store_client/data_decryptor'

module EventStoreClient
  module Mapper
    # Transforms given event's data and encrypts/decrypts selected subset of data
    # based on encryption schema stored in the event itself.
    class Encrypted
      MissingEncryptionKey = Class.new(StandardError)

      attr_reader :key_repository, :serializer, :config
      private :key_repository, :serializer, :config

      # @param key_repository [#find, #create, #encrypt, #decrypt]
      #   See spec/support/dummy_repository.rb for the example of simple in-memory implementation
      # @param config [EventStoreClient::Config]
      # @param serializer [#serialize, #deserialize]
      def initialize(key_repository, config:, serializer: Serializer::Json)
        @key_repository = key_repository
        @config = config
        @serializer = serializer
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash]
      def serialize(event)
        # Links don't need to be encrypted
        return Default.new(serializer: serializer, config: config).serialize(event) if event.link?

        serialized = Serializer::EventSerializer.call(event, serializer: serializer, config: config)
        encryption_schema =
          if event.class.respond_to?(:encryption_schema)
            event.class.encryption_schema
          end

        encryptor = EventStoreClient::DataEncryptor.new(
          data: serialized.data,
          schema: encryption_schema,
          repository: key_repository
        )
        encryptor.call
        serialized.data = encryptor.encrypted_data
        serialized.custom_metadata['encryption'] = encryptor.encryption_metadata
        serialized
      end

      # Decrypts the given event's subset of data.
      # @param event_or_raw_event [EventStoreClient::DeserializedEvent, EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent, EventStore::Client::PersistentSubscriptions::ReadResp::ReadEvent::RecordedEvent]
      # @param skip_decryption [Boolean]
      # @return event [EventStoreClient::DeserializedEvent]
      def deserialize(event_or_raw_event, skip_decryption: false)
        if skip_decryption
          return Default.new(serializer: serializer, config: config).deserialize(event_or_raw_event)
        end

        event =
          if event_or_raw_event.is_a?(EventStoreClient::DeserializedEvent)
            event_or_raw_event
          else
            Serializer::EventDeserializer.call(
              event_or_raw_event, config: config, serializer: serializer
            )
          end

        decrypted_data =
          EventStoreClient::DataDecryptor.new(
            data: event.data,
            schema: event.custom_metadata['encryption'],
            repository: key_repository
          ).call
        event.class.new(**event.to_h.merge(data: decrypted_data, skip_validation: true))
      end
    end
  end
end
# rubocop:enable Metrics/AbcSize, Layout/LineLength, Style/IfUnlessModifier
