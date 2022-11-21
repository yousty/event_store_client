# frozen_string_literal: true

RSpec.describe EventStoreClient::SerializedEvent do
  subject { instance }

  let(:instance) do
    described_class.new(
      id: 'some-id',
      data: { 'foo' => 'bar' },
      custom_metadata: { 'baz' => 'bar' },
      metadata: { 'bar' => 'foo' },
      serializer: serializer
    )
  end
  let(:serializer) { EventStoreClient::Serializer::Json }

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }
  it { is_expected.to have_option(:id) }
  it { is_expected.to have_option(:data) }
  it { is_expected.to have_option(:custom_metadata) }
  it { is_expected.to have_option(:metadata) }
  it { is_expected.to have_option(:serializer) }

  describe '#to_grpc' do
    subject { instance.to_grpc }

    it { is_expected.to be_a(Hash) }
    it 'has correct attributes' do
      aggregate_failures do
        expect(subject[:id]).to eq(string: instance.id)
        expect(subject[:data]).to eq(serializer.serialize(instance.data))
        expect(subject[:custom_metadata]).to eq(serializer.serialize(instance.custom_metadata))
        expect(subject[:metadata]).to eq(instance.metadata)
      end
    end
  end
end
