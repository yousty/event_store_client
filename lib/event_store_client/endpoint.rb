# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Endpoint < Dry::Struct
    def url
      "#{host}:#{port}"
    end

    private

    attribute :host, Types::String
    attribute :port, Types::Coercible::Integer
  end
end
