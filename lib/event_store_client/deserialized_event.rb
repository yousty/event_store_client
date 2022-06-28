# frozen_string_literal: true

require 'dry/schema'

module EventStoreClient
  class DeserializedEvent
    InvalidDataError = Class.new(StandardError)
    private_constant :InvalidDataError

    attr_reader :id, :type, :title, :data, :metadata, :stream_name, :stream_revision

    # @args [Hash] opts
    # @option opts [Boolean] :skip_validation
    # @option opts [Hash] :data
    # @option opts [Hash] :metadata
    # @option opts [String] :type
    # @option opts [String] :title
    # @option opts [String] :stream_name
    # @option opts [Integer] :stream_revision
    # @option opts [UUID] :id
    #
    def initialize(args = {})
      validate(args[:data]) unless args[:skip_validation]

      @data = args.fetch(:data) { {} }
      @type = args[:type] || self.class.name
      @metadata =
        args.fetch(:metadata) { {} }
            .merge(
              'type' => @type,
              'content-type' => payload_content_type
            )
      @stream_name = args[:stream_name]
      @stream_revision = args[:stream_revision]
      @title = args[:title]
      @id = args[:id]
    end

    # event schema
    def schema; end

    # content type of the event data
    def payload_content_type
      return 'application/json' if EventStoreClient.config.adapter_type == :grpc

      'application/vnd.eventstore.events+json'
    end

    private

    def validate(data)
      return unless schema

      validation = schema.call(data || {})

      return unless validation.errors.any?

      raise(InvalidDataError.new(message: "#{schema.class.name} #{validation.errors.to_h}"))
    end
  end
end
