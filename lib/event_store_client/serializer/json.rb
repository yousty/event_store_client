# frozen_string_literal: true

module Serializer
  module Json
    def self.deserialize(data)
      return data if data.is_a?(Hash)

      JSON.parse(data)
    end

    def self.serialize(data)
      return data if data.is_a?(String)

      JSON.generate(data)
    end
  end
end
