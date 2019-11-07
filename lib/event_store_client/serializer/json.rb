# frozen_string_literal: true

module Serializer
  module Json
    def self.deserialize(data)
      JSON.parse(data)
    end

    def self.serialize(data)
      JSON.generate(data)
    end
  end
end
