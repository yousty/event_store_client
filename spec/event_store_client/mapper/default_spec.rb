# frozen_string_literal: true

RSpec.describe EventStoreClient::Mapper::Default do
  let(:instance) { described_class.new(serializer: serializer, config: config) }
  let(:config) { EventStoreClient.config }
  let(:serializer) { EventStoreClient::Serializer::Json }

  describe '#serialize' do
    subject { instance.serialize(event) }

    let(:event) { EventStoreClient::DeserializedEvent.new(data: { foo: :bar }) }

    before do
      allow(EventStoreClient::Serializer::EventSerializer).to receive(:call).and_call_original
    end

    it { is_expected.to be_a(EventStoreClient::SerializedEvent) }
    it 'has correct structure' do
      aggregate_failures do
        expect(subject.id).to be_a(String)
        expect(subject.data).to eq('foo' => 'bar')
        expect(subject.custom_metadata).to match(hash_including('created_at'))
        expect(subject.metadata).to match(hash_including('content-type', 'type'))
      end
    end
    it 'serializes it using EventSerializer' do
      subject
      expect(EventStoreClient::Serializer::EventSerializer).to(
        have_received(:call).with(event, serializer: serializer, config: config)
      )
    end
  end

  describe '#deserialize' do
    subject { instance.deserialize(event) }

    let(:event) { EventStoreClient::DeserializedEvent.new(data: { foo: :bar }) }

    context 'when event is a DeserializedEvent' do
      it 'returns that event' do
        is_expected.to eq(event)
      end
    end

    context 'when event is a raw event' do
      subject { instance.deserialize(raw_event) }

      let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
      let(:raw_event) do
        append_and_reload(stream_name, event, skip_deserialization: true).event.event
      end

      before do
        allow(EventStoreClient::Serializer::EventDeserializer).to receive(:call).and_call_original
      end

      it { is_expected.to be_a(EventStoreClient::DeserializedEvent) }
      it 'deserializes it using EventDeserializer' do
        subject
        expect(EventStoreClient::Serializer::EventDeserializer).to(
          have_received(:call).with(raw_event, serializer: serializer, config: config)
        )
      end
    end
  end
end
