# frozen_string_literal: true

RSpec.describe EventStoreClient::SerializedEvent do
  subject { instance }

  let(:instance) do
    described_class.new(
      id: 'some-id',
      data: data,
      custom_metadata: custom_metadata,
      metadata: { 'bar' => 'foo' },
      serializer: serializer
    )
  end
  let(:custom_metadata) { { 'baz' => 'bar' } }
  let(:data) { { 'foo' => 'bar' } }
  let(:serializer) { EventStoreClient::Serializer::Json }

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }
  it { is_expected.to have_option(:id) }
  it { is_expected.to have_option(:data) }
  it { is_expected.to have_option(:custom_metadata) }
  it { is_expected.to have_option(:metadata) }
  it { is_expected.to have_option(:serializer) }

  describe '#to_grpc' do
    subject { instance.to_grpc }

    shared_examples 'acceptable by GRPC' do
      it 'is acceptable by GRPC' do
        msg_klass = EventStore::Client::Streams::AppendReq::ProposedMessage
        event_klass = EventStore::Client::Streams::AppendReq::ProposedMessage
        aggregate_failures do
          expect { msg_klass.new(subject) }.not_to raise_error
          expect { event_klass.new(subject) }.not_to raise_error
        end
      end
    end

    it { is_expected.to be_a(Hash) }
    it 'has correct attributes' do
      aggregate_failures do
        expect(subject[:id]).to eq(string: instance.id)
        expect(subject[:data]).to eq(serializer.serialize(data))
        expect(subject[:custom_metadata]).to eq(serializer.serialize(custom_metadata))
        expect(subject[:metadata]).to eq(instance.metadata)
      end
    end
    it_behaves_like 'acceptable by GRPC'

    context 'when data contains chars that can not be converted to ASCII-8BIT' do
      let(:data) { { 'foo' => 'Zürich' } }

      it 'converts it to ASCII-8BIT' do
        expect(subject[:data].encoding.to_s).to eq('ASCII-8BIT')
      end
      it_behaves_like 'acceptable by GRPC'
    end

    context 'when customdata contains chars that can not be converted to ASCII-8BIT' do
      let(:custom_metadata) { { 'baz' => 'Zürich' } }

      it 'converts it to ASCII-8BIT' do
        expect(subject[:custom_metadata].encoding.to_s).to eq('ASCII-8BIT')
      end
      it_behaves_like 'acceptable by GRPC'
    end
  end
end
