# frozen_string_literal: true

require 'securerandom'
require 'support/dummy_repository'

module EventStoreClient
  RSpec.describe DataDecryptor do
    describe '#call' do
      let(:repository) { DummyRepository.new }

      subject { described_class.new(data: data, schema: schema, repository: repository) }

      it 'returns decrypted data' do
        expect(subject.call).to eq(
          user_id: user_id,
          first_name: 'Anakin',
          last_name: 'Skylwalker',
          profession: 'Jedi'
        )
      end

      it 'updates the data reader' do
        subject.call
        expect(subject.decrypted_data).to eq(
          user_id: user_id,
          first_name: 'Anakin',
          last_name: 'Skylwalker',
          profession: 'Jedi'
        )
      end

      it 'skips the decryption of non-existing keys' do
        schema[:attributes] << :side
        expect(subject.call).to eq(
          user_id: user_id,
          first_name: 'Anakin',
          last_name: 'Skylwalker',
          profession: 'Jedi'
        )
      end
    end

    let(:key_repository) { DummyRepository.new }
    let(:user_id) { SecureRandom.uuid }
    let(:data) do
      {
        user_id: user_id,
        first_name: 'es_encrypted',
        last_name: 'es_encrypted',
        profession: 'Jedi',
        es_encrypted: 'darthvader'
      }
    end

    let(:schema) do
      {
        key: ->(data) { data[:user_id] },
        attributes: %i[first_name last_name]
      }
    end
  end
end
