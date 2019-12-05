# frozen_string_literal: true

module EventStoreClient
  RSpec.describe Mapper::Encrypted do
    let(:data) do
      {
        'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
        'email' => 'darth@vader.sv',
        'first_name' => 'Anakin',
        'last_name' => 'Skylwalker'
      }
    end

    describe '#serialize' do
      let(:encrypted_data) do
        {
          'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          'email' => 'encrypted',
          'first_name' => 'encrypted',
          'last_name' => 'Skylwalker'
        }
      end

      let(:user_registered) { EncryptedEvent.new(data: data) }

      subject { described_class.new(DummyRepository.new).serialize(user_registered) }

      it 'returns serialized event' do
        expect(subject).to be_kind_of(EventStoreClient::Event)
        expect(subject.data).to eq(JSON.generate(encrypted_data))
        expect(subject.metadata).to include('created_at')
        expect(subject.metadata).to include('encryption')
        expect(subject.type).to eq('EncryptedEvent')
      end
    end

    describe '#deserialize' do
      # TODO
    end
  end
end

class DummyRepository
  class Key
    attr_accessor :iv, :cipher, :id
    def initialize(id:, **)
      @id = id
    end
  end

  def find(user_id)
    Key.new(id: user_id)
  end

  def encrypt(*)
    'encrypted'
  end

  def decrypt(*)
    'decrypted'
  end
end

class EncryptedEvent < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:email).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
    end
  end

  def self.encryption_schema
    {
      'email' => ->(data) { data['user_id'] },
      'first_name' => ->(data) { data['user_id'] }
    }
  end
end

class SerializedEncryptedEvent
  attr_reader :type

  def metadata
    '{"created_at":"2019-12-05 19:37:38 +0100"}'
  end

  def data
    '{"user_id":"dab48d26-e4f8-41fc-a9a8-59657e590716","email":"encrypted","first_name":"encrypted"}' # rubocop:disable Metrics/LineLength
  end

  private

  def initialize(type:)
    @type = type
  end
end
