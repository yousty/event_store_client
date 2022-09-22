# frozen_string_literal: true

RSpec.describe EventStoreClient::DataDecryptor do
  describe '#call' do
    subject { instance.call }

    let(:instance) { described_class.new(data: data, schema: schema, repository: repository) }
    let(:repository) { DummyRepository.new }
    let(:key_repository) { DummyRepository.new }
    let(:user_id) { SecureRandom.uuid }
    let(:data) do
      {
        'user_id' => user_id,
        'first_name' => 'es_encrypted',
        'last_name' => 'es_encrypted',
        'profession' => 'Jedi',
        'es_encrypted' => DummyRepository.encrypt(message_to_encrypt)
      }
    end
    let(:decrypted_data) do
      {
        'user_id' => user_id,
        'first_name' => 'Anakin',
        'last_name' => 'Skywalker',
        'profession' => 'Jedi'
      }
    end
    let(:schema) do
      {
        key: user_id,
        attributes: %i[first_name last_name]
      }
    end
    let(:message_to_encrypt) { decrypted_data.slice('first_name', 'last_name').to_json }

    before do
      DummyRepository.new.encrypt(
        key: DummyRepository::Key.new(id: user_id),
        message: message_to_encrypt
      )
    end

    it 'returns decrypted data' do
      expect(subject).to eq(decrypted_data)
    end
    it 'skips the decryption of non-existing keys' do
      schema[:attributes] << :side
      expect(subject).to eq(decrypted_data)
    end

    context 'when key is not found' do
      let(:error) { Class.new(StandardError).new }

      before do
        allow(repository).to receive(:find).and_raise(error)
      end

      it 'raises that error' do
        expect { subject }.to raise_error(error)
      end
    end

    context 'when data has not been encrypted (schema is nil)' do
      let(:instance) do
        described_class.new(data: decrypted_data, schema: nil, repository: repository)
      end

      it 'returns decrypted data' do
        expect(subject).to eq(decrypted_data)
      end
    end
  end
end
