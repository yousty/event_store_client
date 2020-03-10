# frozen_string_literal: true

require 'support/encrypted_event'
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
          'first_name' => 'es_encrypted',
          'last_name' => 'es_encrypted',
          'profession' => 'Jedi',
          'es_encrypted' => 'darthvader'
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
      let(:encryption_metadata) do
        {
          iv: 'DarthSidious',
          key: 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          attributes: %i[first_name last_name]
        }
      end

      let(:encrypted_data) do
        {
          'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          'first_name' => 'es_encrypted',
          'last_name' => 'es_encrypted',
          'profession' => 'Jedi',
          'es_encrypted' => 'darthvader'
        }
      end

      let(:decrypted_data) do
        {
          user_id: 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          first_name: 'Anakin',
          last_name: 'Skylwalker',
          profession: 'Jedi'
        }
      end

      let(:user_registered) do
        EventStoreClient::Event.new(
          data: JSON.generate(encrypted_data),
          metadata: JSON.generate(encryption: encryption_metadata),
          type: 'EncryptedEvent'
        )
      end

      subject { described_class.new(DummyRepository.new).deserialize(user_registered) }

      it 'returns deserialized event' do
        expect(subject).to be_kind_of(EncryptedEvent)
        expect(subject.data).to eq(decrypted_data)
        expect(subject.metadata).to include('created_at')
        expect(subject.data).not_to include('es_encrypted')
      end
    end
  end
end
