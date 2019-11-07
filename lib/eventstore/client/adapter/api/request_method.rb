# frozen_string_literal: true

module Eventstore
  module Client
    module Adapter
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

          def initialize(name)
            raise InvalidEndDateError unless name.to_s.in?(SUPPORTED_METHODS)

            @name = name.to_s
          end

          SUPPORTED_METHODS = %w[get post].freeze
        end
      end
    end
  end
end
