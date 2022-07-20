# frozen_string_literal: true

RSpec.describe EventStoreClient::DataEncryptor do
  describe '#call' do
    subject { instance.call }

    let(:instance) { described_class.new(data: data, schema: schema, repository: repository) }
    let(:repository) { DummyRepository.new }
    let(:key_repository) { DummyRepository.new }
    let(:user_id) { SecureRandom.uuid }
    let(:data) do
      {
        user_id: user_id,
        first_name: 'Anakin',
        last_name: 'Skywalker',
        profession: 'Jedi'
      }
    end
    let(:schema) do
      {
        key: ->(data) { data[:user_id] },
        attributes: %i[first_name last_name]
      }
    end
    let(:message_to_encrypt) { data.slice(:first_name, :last_name).to_json }

    it 'returns encrypted data' do
      expect(subject).to eq(
        'user_id' => user_id,
        'first_name' => 'es_encrypted',
        'last_name' => 'es_encrypted',
        'profession' => 'Jedi',
        'es_encrypted' => DummyRepository.encrypt(message_to_encrypt)
      )
    end
    it 'updates the encrypted data reader' do
      subject
      expect(instance.encrypted_data).to eq(
        'user_id' => user_id,
        'first_name' => 'es_encrypted',
        'last_name' => 'es_encrypted',
        'profession' => 'Jedi',
        'es_encrypted' => DummyRepository.encrypt(message_to_encrypt)
      )
    end
    it 'skips the encryption of non-existing keys' do
      schema[:attributes] << :side
      subject
      expect(instance.encrypted_data).to eq(
        'user_id' => user_id,
        'first_name' => 'es_encrypted',
        'last_name' => 'es_encrypted',
        'profession' => 'Jedi',
        'es_encrypted' => DummyRepository.encrypt(message_to_encrypt)
      )
    end
  end
end
