# frozen_string_literal: true

RSpec.describe EventStoreClient::Utils do
  describe '.uuid_to_str' do
    subject { described_class.uuid_to_str(uuid) }

    let(:uuid) { EventStore::Client::UUID.new(string: uuid_str) }
    let(:uuid_str) { SecureRandom.uuid }

    context 'when object contains string representation of UUID' do
      it 'returns it' do
        is_expected.to eq(uuid_str)
      end
    end

    context 'when object is structured representation of UUID' do
      let(:uuid) do
        EventStore::Client::UUID.new(
          structured: { most_significant_bits: msb, least_significant_bits: lsb }
        )
      end
      let(:msb) { 8789121028307961377 }
      let(:lsb) { -8393389205121028596 }

      it 'returns string representation of UUID' do
        is_expected.to eq('79f93b02-2c36-4621-8b84-b0fcef29ae0c')
      end
    end
  end
end
