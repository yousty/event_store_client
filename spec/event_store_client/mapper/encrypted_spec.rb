# frozen_string_literal: true

require 'support/dummy_repository'

module EventStoreClient
  RSpec.describe Mapper::Encrypted do
    let(:data) do
      {
        'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
        'first_name' => 'Anakin',
        'last_name' => 'Skylwalker',
        'profession' => 'Jedi'
      }
    end

    describe '#serialize' do
      let(:encrypted_data) do
        {
          'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          'first_name' => 'encrypted',
          'last_name' => 'encrypted',
          'profession' => 'Jedi',
          'encrypted' => 'darthvader'
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

class SerializedEncryptedEvent
  attr_reader :type

  def metadata
    '{"created_at":"2019-12-05 19:37:38 +0100"}'
  end

  def data
    JSON.generate(
      user_id: 'dab48d26-e4f8-41fc-a9a8-59657e590716',
      first_name: 'encrypted',
      last_name: 'encrypted',
      profession: 'Jedi',
      encrypted: 'darthvader'
    )
  end

  private

  def initialize(type:)
    @type = type
  end
end
