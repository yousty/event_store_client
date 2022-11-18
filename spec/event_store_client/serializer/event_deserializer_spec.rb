# frozen_string_literal: true

RSpec.describe EventStoreClient::Serializer::EventDeserializer do
  let(:instance) { described_class.new(serializer: serializer) }
  let(:serializer) { EventStoreClient::Serializer::Json }

  describe '.call' do
    subject { described_class.call(raw_event, serializer: serializer) }

    let(:raw_event) do
      EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent.new(
        id: { string: 'some-id' },
        stream_identifier: { stream_name: 'some-stream' }
      )
    end

    it 'deserializes given raw event' do
      is_expected.to be_a(EventStoreClient::DeserializedEvent)
    end
  end

  describe '#call' do
    subject { instance.call(raw_event) }

    let(:raw_event) do
      EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent.new(
        id: { string: id },
        stream_identifier: { stream_name: stream_name },
        stream_revision: stream_revision,
        prepare_position: prepare_position,
        commit_position: commit_position,
        metadata: metadata,
        custom_metadata: serializer.serialize(custom_metadata),
        data: serializer.serialize(data)
      )
    end
    let(:id) { SecureRandom.uuid }
    let(:stream_name) { 'some-stream' }
    let(:stream_revision) { rand(10) }
    let(:prepare_position) { rand(1_000..2_000) }
    let(:commit_position) { rand(1_000..2_000) }
    let(:metadata) { { 'foo' => 'bar', 'type' => event_type } }
    let(:custom_metadata) { { 'bar' => 'baz' } }
    let(:data) { { 'baz' => 'foo' } }
    let(:event_type) { 'some-event' }

    it { is_expected.to be_a(EventStoreClient::DeserializedEvent) }
    it 'deserializes it correctly' do
      aggregate_failures do
        expect(subject.id).to eq(id)
        expect(subject.stream_name).to eq(stream_name)
        expect(subject.stream_revision).to eq(stream_revision)
        expect(subject.prepare_position).to eq(prepare_position)
        expect(subject.commit_position).to eq(commit_position)
        expect(subject.metadata).to(
          eq(metadata.merge(custom_metadata).merge('content-type' => 'application/json'))
        )
        expect(subject.title).to eq("#{stream_revision}@#{stream_name}")
        expect(subject.data).to eq(data)
        expect(subject.type).to eq(event_type)
      end
    end

    context 'when event type matches existing class' do
      let(:event_type) { 'SomeEvent' }
      let(:event_class) { Class.new(EventStoreClient::DeserializedEvent) }

      before do
        stub_const(event_type, event_class)
      end

      it { is_expected.to be_a(SomeEvent) }
    end

    context 'when event type is absent' do
      let(:metadata) { { 'foo' => 'bar' } }

      it { is_expected.to be_a(EventStoreClient::DeserializedEvent) }
    end

    context 'when data is absent' do
      before do
        raw_event.data = ''
      end

      it 'defaults it to empty hash' do
        expect(subject.data).to eq({})
      end
    end

    context 'when data is absent' do
      before do
        raw_event.custom_metadata = ''
      end

      it 'assigns correct metadata value' do
        expect(subject.metadata).to eq(metadata.merge('content-type' => 'application/json'))
      end
    end

    context "when event's data does not match event's schema" do
      let(:event_type) { 'EncryptedEvent' }

      it 'deserializes it' do
        is_expected.to be_a(EncryptedEvent)
      end
    end
  end
end
