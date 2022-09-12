# frozen_string_literal: true

require 'dry-types'

module EventStoreClient
  module Types
    UUID_REGEXP =
      /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\z/i.
      freeze

    include Dry.Types()

    UUID = Types::Strict::String.constrained(
      format: UUID_REGEXP
    )
  end
end
