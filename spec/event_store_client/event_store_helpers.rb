# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class SomethingHappened < DeserializedEvent
    def schema
      Dry::Schema.Params do
      end
    end
  end

  class DummyHandler
    def self.call(event)
      puts "Handled #{event.class.name}"
    end
  end
end
