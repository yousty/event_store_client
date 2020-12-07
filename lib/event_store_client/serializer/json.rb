# frozen_string_literal: true

module Serializer
  module Json
    def self.deserialize(data)
      JSON.parse(data)
    rescue JSON::ParserError
      { 'message' => data }
    end

    def self.serialize(data)
      return data if data.is_a?(String)

      JSON.generate(data)
    end
  end
end
