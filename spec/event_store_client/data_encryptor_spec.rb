# frozen_string_literal: true

require 'securerandom'

module EventStoreClient
  RSpec.describe DataEncryptor do
    describe '#call' do
      let(:repository) { DummyRepository.new }

      subject { described_class.new(data: data, schema: schema, repository: repository) }

      it 'returns encrypted data' do
        expect(subject.call).to eq(
          user_id: user_id,
          first_name: 'encrypted',
          last_name: 'encrypted',
          profession: 'Jedi',
          encrypted: 'darthvader'
        )
      end

      it 'updates the encrypted data reader' do
        subject.call
        expect(subject.encrypted_data).to eq(
          user_id: user_id,
          first_name: 'encrypted',
          last_name: 'encrypted',
          profession: 'Jedi',
          encrypted: 'darthvader'
        )
      end
    end

    let(:key_repository) { DummyRepository.new }
    let(:user_id) { SecureRandom.uuid }
    let(:data) do
      {
        user_id: user_id,
        first_name: 'Anakin',
        last_name: 'Skylwalker',
        profession: 'Jedi'
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
    'darthvader'
  end

  def decrypt(*)
    JSON.gnereate(first_name: 'Anakin', last_name: 'Skylwalker')
  end
end
