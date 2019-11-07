# frozen_string_literal: true

require "dry-struct"
require 'securerandom'
require 'json'

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
        hash_meta =
          JSON.parse(args[:metadata] || "{}").merge(created_at: Time.now)
        args[:metadata] = JSON.generate(hash_meta)
        super(args)
      end
    end
  end
end
