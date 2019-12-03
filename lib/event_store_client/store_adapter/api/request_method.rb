# frozen_string_literal: true

module EventStoreClient
  module StoreAdapter
    module Api
      class RequestMethod
        InvalidMethodError = Class.new(StandardError)
        def ==(other)
          name == other.to_s
        end

        def to_s
          name
        end

        private

        attr_reader :name

        SUPPORTED_METHODS = %w[get post put delete].freeze

        def initialize(name)
          raise InvalidMethodError unless SUPPORTED_METHODS.include?(name.to_s)

          @name = name.to_s
        end
      end
    end
  end
end
