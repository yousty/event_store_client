# frozen_string_literal: true

module EventStoreClient
  class ReadDirection
    Invalid = Class.new(StandardError)

    def to_sym
      value
    end

    def to_s
      value.to_s
    end

    private

    attr_reader :value

    def initialize(str)
      schema = Schema.new(direction: str)

      unless %w[forwards backwards].include?(schema.direction)
        raise Invalid.new('Allowed values: "forwards", "backwards"')
      end

      @value = schema.direction.capitalize.to_sym
    end


    class Schema < Dry::Struct
      schema schema.strict

      # resolve default types on nil
      transform_types do |type|
        type.constructor do |value|
          value.is_a?(String) ? value.downcase : value
        end
      end

      attribute :direction, Dry::Types['string']
    end
  end
end
