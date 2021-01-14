#!/usr/bin/env ruby
# frozen_string_literal: true

require 'event_store_client/deserialized_event'

class SomethingHappened < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:title).value(:string)
    end
  end
end
