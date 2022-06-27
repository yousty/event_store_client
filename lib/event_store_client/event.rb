# frozen_string_literal: true

require 'dry-struct'
require 'securerandom'
require 'json'

module EventStoreClient
  class Event < Dry::Struct
    attribute :id, Types::Strict::String.optional.default(nil)
    attribute :type, Types::Strict::String
    attribute :title, Types::Strict::String.optional.default(nil)
    attribute :data, Types::Strict::String.default('{}')
    attribute :metadata, Types::Strict::String.default('{}')

    def initialize(args = {})
      args[:id] = SecureRandom.uuid if args[:id].nil?
      hash_meta = JSON.parse(args[:metadata] || '{}')
      hash_meta['created_at'] ||= Time.now
      args[:metadata] = JSON.generate(hash_meta)
      super(args)
    end
  end
end
