# frozen_string_literal: true

RSpec.describe EventStoreClient::Mapper::Encrypted do
  let(:config) { EventStoreClient.config }
  let(:instance) do
    described_class.new(DummyRepository.new, serializer: serializer, config: config)
  end
  let(:serializer) { EventStoreClient::Serializer::Json }
  let(:data) do
    {
      'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
      'first_name' => 'Anakin',
      'last_name' => 'Skywalker',
      'profession' => 'Jedi'
    }
  end

  describe '#serialize' do
    subject { instance.serialize(event) }

    let(:encrypted_data) do
      {
        'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
        'first_name' => 'es_encrypted',
        'last_name' => 'es_encrypted',
        'profession' => 'Jedi',
        'es_encrypted' => DummyRepository.encrypt(data.slice('first_name', 'last_name').to_json)
      }
    end
    let(:event) { EncryptedEvent.new(data: data) }

    before do
      allow(EventStoreClient::Serializer::EventSerializer).to receive(:call).and_call_original
    end

    it { is_expected.to be_a(EventStoreClient::SerializedEvent) }
    it 'has correct structure' do
      aggregate_failures do
        expect(subject.id).to be_a(String)
        expect(subject.data).to eq(encrypted_data)
        expect(subject.custom_metadata).to match(hash_including('created_at', 'encryption'))
        expect(subject.metadata).to match(hash_including('content-type', 'type'))
      end
    end
    it 'serializes it using EventSerializer' do
      subject
      expect(EventStoreClient::Serializer::EventSerializer).to(
        have_received(:call).with(event, serializer: serializer, config: config)
      )
    end

    context 'when event is a link' do
      let(:event) { EncryptedEvent.new(data: data, type: '$>') }

      it 'does not encrypt its data' do
        expect(subject.data).to eq(data)
      end
    end
  end

  describe '#deserialize' do
    context 'when event is a EventStoreClient::DeserializedEvent' do
      subject { instance.deserialize(event) }

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
          'es_encrypted' => DummyRepository.encrypt(message_to_encrypt)
        }
      end
      let(:decrypted_data) do
        {
          'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
          'first_name' => 'Anakin',
          'last_name' => 'Skywalker',
          'profession' => 'Jedi'
        }
      end
      let!(:event) do
        event = EncryptedEvent.new(
          data: encrypted_data,
          custom_metadata: { encryption: encryption_metadata }
        )
        append_and_reload("some-stream$#{SecureRandom.uuid}", event, skip_decryption: true)
      end
      let(:message_to_encrypt) do
        decrypted_data.slice('first_name', 'last_name').to_json
      end

      before do
        DummyRepository.new.encrypt(
          key: DummyRepository::Key.new(id: decrypted_data['user_id']),
          message: message_to_encrypt
        )
        allow(EncryptedEvent).to receive(:new).and_call_original
      end

      it 'returns decrypted event' do
        aggregate_failures do
          expect(subject).to be_a(EncryptedEvent)
          expect(subject.data).to eq(decrypted_data)
          expect(subject.data).not_to include('es_encrypted', 'created_at')
          expect(subject.metadata).to include('type', 'content-type')
        end
      end
      it 'skips validation' do
        subject
        expect(EncryptedEvent).to have_received(:new).with(hash_including(skip_validation: true))
      end
    end
  end
end
