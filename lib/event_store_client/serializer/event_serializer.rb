# frozen_string_literal: true

module EventStoreClient
  module Serializer
    class EventSerializer
      # So far there are only these keys can be persisted in the metadata. You can pass **whatever**
      # you want into a metadata hash, but all keys, except these - will be rejected. Define
      # whitelisted keys and cut unwanted keys explicitly(later in this class).
      ALLOWED_EVENT_METADATA = %w[type content-type].freeze

      class << self
        # @param event [EventStoreClient::DeserializedEvent]
        # @param config [EventStoreClient::Config]
        # @param serializer [#serialize, #deserialize]
        # @return [EventStoreClient::SerializedEvent]
        def call(event, config:, serializer: Serializer::Json)
          new(serializer: serializer, config: config).call(event)
        end
      end

      attr_reader :serializer, :config
      private :serializer, :config

      # @param serializer [#serialize, #deserialize]
      # @param config [EventStoreClient::Config]
      def initialize(serializer:, config:)
        @serializer = serializer
        @config = config
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [EventStoreClient::SerializedEvent]
      def call(event)
        SerializedEvent.new(
          id: event.id || SecureRandom.uuid,
          data: data(event),
          metadata: metadata(event),
          custom_metadata: custom_metadata(event),
          serializer: serializer
        )
      end

      private

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash]
      def metadata(event)
        metadata = serializer.deserialize(serializer.serialize(event.metadata))
        # 'created' is returned in the metadata hash of the event when reading from a stream. It,
        # however, can not be overridden - it is always defined automatically by EventStore db when
        # appending new event. Thus, just ignore it - no need even to mention it in the
        # #log_metadata_difference method's message.
        metadata = metadata.slice(*(metadata.keys - ['created']))
        filtered_metadata = metadata.slice(*ALLOWED_EVENT_METADATA)
        log_metadata_difference(metadata) unless filtered_metadata == metadata
        filtered_metadata
      end

      # Compute custom metadata for the event. **Exactly these** values you can see in ES admin's
      # web UI under "Metadata" section of the event.
      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash]
      def custom_metadata(event)
        custom_metadata = serializer.deserialize(serializer.serialize(event.custom_metadata))
        custom_metadata['created_at'] ||= Time.now.utc.to_s
        custom_metadata
      end

      # @param event [EventStoreClient::DeserializedEvent]
      # @return [Hash, String]
      def data(event)
        # Link events are special events. They contain special string value which shouldn't be
        # serialized.
        return event.data if event.link?

        serializer.deserialize(serializer.serialize(event.data))
      end

      # @param metadata [Hash]
      # @return [void]
      def log_metadata_difference(metadata)
        rest_hash = metadata.slice(*(metadata.keys - ALLOWED_EVENT_METADATA))
        debug_message = <<~TEXT
          Next keys were filtered from metadata during serialization: \
          #{(metadata.keys - ALLOWED_EVENT_METADATA).map(&:inspect).join(', ')}. If you would like \
          to provide your custom values in the metadata - please provide them via custom_metadata. \
          Example: EventStoreClient::DeserializedEvent.new(custom_metadata: #{rest_hash.inspect})
        TEXT
        config.logger&.debug(debug_message)
      end
    end
  end
end
