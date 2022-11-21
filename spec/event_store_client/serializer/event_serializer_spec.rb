# frozen_string_literal: true

RSpec.describe EventStoreClient::Serializer::EventSerializer do
  let(:instance) { described_class.new(serializer: serializer) }
  let(:serializer) { EventStoreClient::Serializer::Json }

  describe 'constants' do
    describe 'ALLOWED_EVENT_METADATA' do
      subject { described_class::ALLOWED_EVENT_METADATA }

      it { is_expected.to eq(['type', 'content-type', 'created_at']) }
      it { is_expected.to be_frozen }
    end
  end

  describe '.call' do
    subject { described_class.call(event, serializer: serializer) }

    let(:event) { EventStoreClient::DeserializedEvent.new }

    it 'serializes given event' do
      is_expected.to be_a(EventStoreClient::SerializedEvent)
    end
  end

  describe '#call', timecop: true do
    subject { instance.call(event) }

    let(:event) do
      EventStoreClient::DeserializedEvent.new(data: data, metadata: metadata, id: SecureRandom.uuid)
    end
    let(:data) { { foo: :bar } }
    let(:metadata) { { encryption: { bar: :baz }, transaction: 'some-trx', foo: :bar } }

    it 'serializes event' do
      is_expected.to be_a(EventStoreClient::SerializedEvent)
    end
    it 'assigns correct serializer' do
      expect(subject.serializer).to eq(serializer)
    end
    it 'serializes it properly' do
      aggregate_failures do
        expect(subject.id).to eq(event.id)
        expect(subject.data).to eq('foo' => 'bar')
        expect(subject.custom_metadata).to(
          eq(
            'type' => 'EventStoreClient::DeserializedEvent',
            'created_at' => Time.now.utc.to_s,
            'encryption' => { 'bar' => 'baz' },
            'content-type' => 'application/json',
            'transaction' => 'some-trx'
          )
        )
        expect(subject.metadata).to(
          eq(
            'type' => 'EventStoreClient::DeserializedEvent',
            'created_at' => Time.now.utc.to_s,
            'content-type' => 'application/json'
          )
        )
      end
    end

    context 'when event id is not provided' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(data: data, metadata: metadata)
      end
      let(:uuid) { 'some-uuid' }

      before do
        allow(SecureRandom).to receive(:uuid).and_return(uuid)
      end

      it 'generates it' do
        expect(subject.id).to eq(uuid)
      end
    end

    context 'when event type is provided' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(type: event_type)
      end
      let(:event_type) { 'some-event' }

      it 'takes it into account' do
        aggregate_failures do
          expect(subject.metadata).to include('type' => event_type)
          expect(subject.custom_metadata).to include('type' => event_type)
        end
      end
    end

    context 'when created_at is provided' do
      let(:metadata) { { created_at: time } }
      let(:time) { Time.now.utc - 3601 }

      it 'takes it into account' do
        aggregate_failures do
          expect(subject.metadata).to include('created_at' => time.to_s)
          expect(subject.custom_metadata).to include('created_at' => time.to_s)
        end
      end
    end

    context 'when event is a link event' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(type: '$>', data: 'some-data')
      end

      it 'does not transform the data' do
        expect(subject.data).to eq('some-data')
      end
    end
  end
end
