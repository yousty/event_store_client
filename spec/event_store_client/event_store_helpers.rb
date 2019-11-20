require 'dry-struct'

module EventStoreClient
  class SomethingHappened < Dry::Struct
    attribute :data, EventStoreClient::Types::Strict::Hash
    attribute :metadata, EventStoreClient::Types::Strict::Hash
  end

  class DummyHandler
    def self.call(event)
      puts "Handled #{event.class.name}"
    end
  end
end