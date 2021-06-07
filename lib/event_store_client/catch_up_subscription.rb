# frozen_string_literal: true

module EventStoreClient
  class CatchUpSubscription
    attr_reader :subscriber, :filter
    attr_accessor :position

    def options
      {
        filter: @filter,
        without_system_events: @without_system_events,
        all: {
          position: {
            commit_position: position[:commit_position],
            prepare_position: position[:prepare_position]
          }
        }
      }.compact
    end

    def name
      self.class.name(subscriber)
    end

    def self.name(subscriber)
      subscriber.class.to_s
    end

    private

    def initialize(subscriber, filter: nil, position: nil)
      @filter = filter
      @subscriber = subscriber
      @position = position
      @position ||= {
        commit_position: 0,
        prepare_position: 0
      }
      @without_system_events = true
    end
  end
end
