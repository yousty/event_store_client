# frozen_string_literal: true

require "dry-struct"

module Eventstore
  module Client
    class Event < Dry::Struct
      attr_reader :id

      attribute :data, Types::Strict::String.default("{}")
      attribute :metadata, Types::Strict::String.default("{}")
      attribute :type, Types::Strict::String

      private

      def initialize(**args)
        @id = SecureRandom.uuid
        args[:metadata] = (args[:metadata] || {}).merge(created_at: Time.now)
        super(args)
      end
    end
  end
end
