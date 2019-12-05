# frozen_string_literal: true

require 'securerandom'

module EventStoreClient
  RSpec.describe EncryptionMetadata do
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

    let(:metadata) { described_class.new(data: data, schema: schema) }

    describe '#call' do
      subject { metadata.call }

      it 'returns transformed object' do
        expect(subject).to eq(
          user_id => { attributes: %i[email encrypted] }
        )
      end
    end
  end
end
