# frozen_string_literal: true

require 'dry/schema'

module EventStoreClient
  class DeserializedEvent
    InvalidDataError = Class.new(StandardError)

    attr_reader :id
    attr_reader :type
    attr_reader :title
    attr_reader :data
    attr_reader :metadata

    def schema
      Dry::Schema.Params do
      end
    end

    def initialize(**args)
      validation = schema.call(args[:data] || {})
      raise InvalidDataError.new(message: validation.errors.to_h) if validation.errors.any?

      @data = args.fetch(:data) { {} }
      @metadata = args.fetch(:metadata) { {} }.merge(
        'type' => self.class.name,
        'content-type' => content_type
      )
      @type = args[:type] || self.class.name
      @title = args[:title]
      @id = args[:id]
    end

    def content_type
      return 'application/octet-stream' if EventStoreClient.config.adapter == :grpc

      'application/vnd.eventstore.events+json'
    end
  end
end
