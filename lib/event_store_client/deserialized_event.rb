# frozen_string_literal: true

require 'dry/schema'

module EventStoreClient
  class DeserializedEvent
    InvalidDataError = Class.new(StandardError)
    private_constant :InvalidDataError

    attr_reader :id, :type, :title, :data, :metadata, :stream_name, :stream_revision,
                :prepare_position, :commit_position

    # @args [Hash] opts
    # @option opts [Boolean] :skip_validation
    # @option opts [Hash] :data
    # @option opts [Hash] :metadata
    # @option opts [String] :type
    # @option opts [String] :title
    # @option opts [String] :stream_name
    # @option opts [Integer] :stream_revision
    # @option opts [Integer] :prepare_position
    # @option opts [Integer] :commit_position
    # @option opts [UUID] :id
    #
    def initialize(args = {})
      validate(args[:data]) unless args[:skip_validation]

      @data = args.fetch(:data) { {} }
      @type = args[:type] || self.class.name
      @metadata =
        args.fetch(:metadata) { {} }.
        merge(
          'type' => @type,
          'content-type' => payload_content_type
        )
      @stream_name = args[:stream_name]
      @stream_revision = args[:stream_revision]
      @prepare_position = args[:prepare_position]
      @commit_position = args[:commit_position]
      @title = args[:title]
      @id = args[:id]
    end

    # event schema
    def schema; end

    # content type of the event data
    def payload_content_type
      'application/json'
    end

    # Implements comparison of `EventStoreClient::DeserializedEvent`-s. Two events matches if all of
    # their attributes matches
    # @param other [Object, EventStoreClient::DeserializedEvent]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(EventStoreClient::DeserializedEvent)

      to_h == other.to_h
    end

    # @return [Hash]
    def to_h
      instance_variables.each_with_object({}) do |var, result|
        key = var.to_s
        key[0] = '' # remove @ sign
        result[key.to_sym] = instance_variable_get(var)
      end
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
