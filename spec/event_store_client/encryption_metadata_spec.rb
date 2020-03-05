# frozen_string_literal: true

require 'securerandom'

module EventStoreClient
  RSpec.describe EncryptionMetadata do
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

    let(:metadata) { described_class.new(data: data, schema: schema) }

    describe '#call' do
      subject { metadata.call }

      it 'returns transformed object' do
        expect(subject).to eq(
          key: user_id,
          attributes: %i[first_name last_name]
        )
      end
    end
  end
end
