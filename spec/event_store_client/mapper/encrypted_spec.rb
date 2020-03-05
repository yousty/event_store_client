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
