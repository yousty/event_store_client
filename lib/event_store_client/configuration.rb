# frozen_string_literal: true

module EventStoreClient
  class Config
    include Extensions::OptionsExtension

    option(:eventstore_url) { 'esdb://localhost:2113' }
    option(:per_page) { 20 }
    option(:mapper) { Mapper::Default.new }
    option(:default_event_class) { DeserializedEvent }
    option(:logger)
    option(:skip_deserialization) { false }
    option(:skip_decryption) { false }

    def eventstore_url=(value)
      @eventstore_url =
        if value.is_a?(Connection::Url)
          value
        else
          Connection::UrlParser.new.call(value)
        end
    end

    # @param logger [Logger, nil]
    # @return [Logger, nil]
    def logger=(logger)
      ::GRPC.define_singleton_method :logger do
        @logger ||= logger.nil? ? ::GRPC::DefaultLogger::NoopLogger.new : logger
      end
      @logger = logger
    end
  end

  class << self
    def configure
      yield(config) if block_given?
    end

    def config
      @config ||= Config.new
    end

    def client
      GRPC::Client.new
    end
  end

  # Configuration module to be included in classes required configured variables
  # Usage: include EventStore::Configuration
  # config.eventstore_url
  #
  module Configuration
    # An instance of the EventStoreClient's configuration
    #
    def config
      EventStoreClient.config
    end
  end
end
