# frozen_string_literal: true

module EventStoreClient
  class Config
    include Extensions::OptionsExtension

    CHANNEL_ARGS_DEFAULTS = {
      # These three options reduce delays between failed requests.
      'grpc.min_reconnect_backoff_ms' => 100, # milliseconds
      'grpc.max_reconnect_backoff_ms' => 100, # milliseconds
      'grpc.initial_reconnect_backoff_ms' => 100 # milliseconds
    }.freeze

    option(:eventstore_url) { 'esdb://localhost:2113' }
    option(:per_page) { 20 }
    option(:mapper) { Mapper::Default.new(config: self) }
    option(:default_event_class) { DeserializedEvent }
    option(:logger)
    option(:skip_deserialization) { false }
    option(:skip_decryption) { false }
    # GRPC-specific connection options. This hash will be passed into the `:channel_args` argument
    # of a Stub class of your request. More GRPC options can be found here
    # https://github.com/grpc/grpc/blob/master/include/grpc/impl/codegen/grpc_types.h
    option(:channel_args) # Hash
    option(:name) { :default }
    option(:event_class_resolver) # Proc that excepts a string and returns a class

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

    # @param val [Hash, nil]
    # @return [Hash]
    def channel_args=(val)
      channel_args = CHANNEL_ARGS_DEFAULTS.merge(val&.transform_keys(&:to_s) || {})
      # This options always defaults to `0`. This is because `event_store_client` implements its
      # own retry functional.
      channel_args['grpc.enable_retries'] = 0
      @channel_args = channel_args
    end
  end
end
