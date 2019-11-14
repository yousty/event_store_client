# frozen_string_literal: true

module EventStoreClient
  class Subscription
    attr_accessor :subscribers
    attr_reader :stream, :name

    private
    def initialize(type:, name:)
      @name = name
      @subscribers = []
      @stream = "$et-#{type}"
    end
  end
end
