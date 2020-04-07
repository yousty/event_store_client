# frozen_string_literal: true

module EventStoreClient
  class Subscription
    attr_reader :stream, :subscriber, :name, :observed_streams

    private

    def initialize(subscriber, service:, event_types:)
      subscriber_class =
        if subscriber.class.name == 'Class'
          subscriber.name
        else
          subscriber.class.name
        end
      @name = "#{service}-#{subscriber_class}"
      @subscriber = subscriber
      @stream = name
      @observed_streams = event_types.reduce([]) { |r, type| r << "$et-#{type}" }
    end
  end
end
