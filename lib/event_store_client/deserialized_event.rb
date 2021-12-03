# frozen_string_literal: true

require 'dry/schema'

module EventStoreClient
  class DeserializedEvent
    InvalidDataError = Class.new(StandardError)
    private_constant :InvalidDataError

    attr_reader :id, :type, :title, :data, :metadata

    # @args [Hash] opts
    # @option opts [Boolean] :skip_validation
    # @option opts [Hash] :data
    # @option opts [Hash] :metadata
    # @option opts [String] :type
    # @option opts [String] :title
    # @option opts [UUID] :id
    #
    def initialize(args = {})
      validate(args[:data]) unless args[:skip_validation]

      @data = args.fetch(:data) { {} }
      @metadata =
        args.fetch(:metadata) { {} }
            .merge(
              'type' => self.class.name,
              'content-type' => payload_content_type
            )

      @type = args[:type] || self.class.name
      @title = args[:title]
      @id = args[:id]
    end

    # event schema
    def schema; end

    # content type of the event data
    def payload_content_type
      return 'application/json' if EventStoreClient.config.adapter == :grpc

      'application/vnd.eventstore.events+json'
    end

    private

    def validate(data)
      validation = schema.call(data || {})

      return unless validation.errors.any?

      raise(InvalidDataError.new(message: "#{schema.class.name} #{validation.errors.to_h}"))
    end
  end
end
