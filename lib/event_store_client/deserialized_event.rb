# frozen_string_literal: true

require 'dry-struct'
require 'securerandom'
require 'json'

module EventStoreClient
  class DeserializedEvent < Dry::Struct
    attribute :data, Types::Strict::Hash.default({}.freeze)
    attribute :metadata, Types::Strict::Hash.default({}.freeze)
    attribute :type, Types::Strict::String
  end
end
