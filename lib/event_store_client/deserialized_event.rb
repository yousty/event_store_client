# frozen_string_literal: true

require 'dry-struct'
require 'dry/schema'

module EventStoreClient
  class DeserializedEvent
    InvalidDataError = Class.new(StandardError)

    attr_reader :data
    attr_reader :metadata
    attr_reader :type

    def schema
      Dry::Schema.Params do
      end
    end

    def initialize(**args)
      validation = schema.call(args[:data] || {})
      raise InvalidDataError.new(message: validation.errors.to_h) if validation.errors.any?

      @data = args.fetch(:data) { {} }
      @metadata = args.fetch(:metadata) { {} }
      @type = args[:type] || self.class.name
    end
  end
end
