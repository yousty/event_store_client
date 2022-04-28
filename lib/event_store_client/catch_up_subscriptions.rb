# frozen_string_literal: true

module EventStoreClient
  class CatchUpSubscriptions
    FILTER_DEFAULT_MAX = 32
    FILTER_DEFAULT_CHECKPOINT_INTERVAL_MULTIPLIER = 10000

    include Configuration

    def create_or_load(subscriber, filter: {})
      filter_options = prepare_filter_options(filter)
      position = subscription_store.load_all_position(CatchUpSubscription.name(subscriber))

      subscription = CatchUpSubscription.new(subscriber, position: position, filter: filter_options)
      subscription_store.add(subscription) unless position

      subscriptions << subscription unless @subscriptions.find { |s| s.name == subscription.name }
      subscription
    end

    def each
      subscriptions.each { |subscription| yield(subscription) }
    end

    def listen(subscription)
      connection.subscribe(subscription.options) do |event_data|
        next if recorded_event?(event_data)
        next if confirmation?(event_data)

        new_position = event_data[0]
        event = event_data[1]

        old_position = subscription.position
        subscription.position = new_position
        subscription_store.update_position(subscription)
        next unless event

        logger&.info("Subscription #{subscription.name} received event #{event_data.inspect}")
        subscription.subscriber.call(event)

        if Thread.current.thread_variable_get(:terminate)
          msg =
            "CatchUpSubscriptions: Terminating subscription listener for #{subscription.subscriber}"
          logger&.info(msg)
          break
        end
      rescue StandardError => e
        subscription.position = old_position
        subscription_store.update_position(subscription)
        config.error_handler&.call(e)
      end
    end

    def clean_unused
      subscription_store.clean_unused(subscriptions.map(&:name))
    end

    def reset
      subscription_store.reset(subscriptions)
    end

    private

    attr_reader :connection, :subscriptions, :subscription_store, :logger

    def initialize(connection:, subscription_store:)
      @connection = connection
      @subscription_store = subscription_store
      @subscriptions = []
      @logger = EventStoreClient.config.logger
    end

    def confirmation?(event_data)
      event_data.is_a? EventStore::Client::Streams::ReadResp::SubscriptionConfirmation
    end

    def recorded_event?(event_data)
      event_data.is_a? EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent
    end

    def prepare_filter_options(filter)
      return if filter.nil? || filter.empty?

      {
        event_type: filter[:event_type],
        stream_identifier: filter[:stream_identifier],
        max: FILTER_DEFAULT_MAX,
        checkpointIntervalMultiplier: FILTER_DEFAULT_CHECKPOINT_INTERVAL_MULTIPLIER
      }.compact
    end
  end
end
