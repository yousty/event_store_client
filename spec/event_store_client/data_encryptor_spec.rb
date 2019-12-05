# frozen_string_literal: true

require 'securerandom'

module EventStoreClient
  RSpec.describe DataEncryptor do
    let(:key_repository) { DummyRepository.new }
    let(:user_id) { SecureRandom.uuid }
    let(:data) do
      {
        user_id: user_id,
        email: 'darth@vader.sv',
        encrypted: 'Foo',
        not_encrypted: 'Bar'
      }
    end

    let(:schema) do
      {
        email: ->(data) { data[:user_id] },
        encrypted: ->(data) { data[:user_id] }
      }
    end

    describe '#call' do
      let(:repository) { DummyRepository.new }

      subject { described_class.new(data: data, schema: schema, repository: repository).call }

      it 'returns encrypted data' do
        expect(subject).to eq(
          user_id: user_id,
          email: 'encrypted',
          encrypted: 'encrypted',
          not_encrypted: 'Bar'
        )
      end
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
