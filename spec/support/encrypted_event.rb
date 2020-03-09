# frozen_string_literal: true

class EncryptedEvent < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
      required(:profession).value(:string)
    end
  end

  def self.encryption_schema
    {
      key: ->(data) { data[:user_id] },
      attributes: %i[first_name last_name]
    }
  end
end
