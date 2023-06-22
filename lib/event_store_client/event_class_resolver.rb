# frozen_string_literal: true

module EventStoreClient
  class EventClassResolver
    attr_reader :config
    private :config

    # @param config [EventStoreClient::Config]
    def initialize(config)
      @config = config
    end

    # @param event_type [String, nil]
    # @return [Class<EventStoreClient::DeserializedEvent>]
    def resolve(event_type)
      return config.event_class_resolver.(event_type) || config.default_event_class if config.event_class_resolver

      Object.const_get(event_type)
    rescue NameError, TypeError
      config.logger&.debug(<<~TEXT.strip)
        Unable to resolve class by `#{event_type}' event type. \
        Picking default `#{config.default_event_class}' event class to instantiate the event.
      TEXT
      config.default_event_class
    end
  end
end
