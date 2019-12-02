# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class Endpoint < Dry::Struct
    attribute :host, Types::String
    attribute :port, Types::Coercible::Integer

    def url
      "#{host}:#{port}"
    end
  end
end
