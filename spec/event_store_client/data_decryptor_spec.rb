# frozen_string_literal: true

require 'securerandom'
require 'support/dummy_repository'

module EventStoreClient
  RSpec.describe DataDecryptor do
    describe '#call' do
      let(:repository) { DummyRepository.new }

      subject { described_class.new(data: data, schema: schema, repository: repository) }

      let(:key_repository) { DummyRepository.new }
      let(:user_id) { SecureRandom.uuid }

      let(:data) do
        {
          'user_id' => user_id,
          'first_name' => 'es_encrypted',
          'last_name' => 'es_encrypted',
          'profession' => 'Jedi',
          'es_encrypted' => 'darthvader'
        }
      end
      let(:decrypted_data) do
        {
          'user_id' => user_id,
          'first_name' => 'Anakin',
          'last_name' => 'Skylwalker',
          'profession' => 'Jedi'
        }
      end

      let(:schema) do
        {
          key: user_id,
          attributes: %i[first_name last_name]
        }
      end

      it 'returns decrypted data' do
        expect(subject.call).to eq(decrypted_data)
      end

      it 'skips the decryption of non-existing keys' do
        schema[:attributes] << :side
        expect(subject.call).to eq(decrypted_data)
      end

      context 'when key is not found' do
        it 'returns does not changed decrypted data' do
          allow_any_instance_of(DummyRepository).to receive(:find).with(user_id).and_raise
          expect(subject.call).to eq(data)
        end
      end

      context 'when data has not been encrypted (schema is nil)' do
        subject { described_class.new(data: decrypted_data, schema: nil, repository: repository) }

        it 'returns decrypted data' do
          expect(subject.call).to eq(decrypted_data)
        end
      end
    end
  end
end
