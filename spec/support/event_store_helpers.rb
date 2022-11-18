# frozen_string_literal: true

module EventStoreClient
  class SomethingHappened < DeserializedEvent
    def schema
      Dry::Schema.Params do
      end
    end
  end
end
