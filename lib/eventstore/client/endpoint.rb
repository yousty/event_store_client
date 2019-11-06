# frozen_string_literal: true

require "dry-struct"

module Eventstore
  module Client
    module Types
      include Dry.Types()
    end

    class Endpoint < Dry::Struct
      def url
        "#{host}:#{port}"
      end

      private

      attribute :host, Types::String
      attribute :port, Types::Coercible::Integer
    end
  end
end
