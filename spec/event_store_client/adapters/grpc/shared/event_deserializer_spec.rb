# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Shared::EventDeserializer do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe '#call' do
    subject { instance.call(raw_event, skip_decryption: skip_decryption) }

    let(:raw_event) do
      EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent.new(
        id: { string: 'some-id' },
        stream_identifier: { stream_name: 'some-stream' },
        stream_revision: rand(100),
        commit_position: rand(1000..2000),
        prepare_position: rand(1000..2000),
        metadata: { type: 'some-event' }
      )
    end
    let(:skip_decryption) { false }

    shared_examples 'deserialized event' do
      it { is_expected.to be_a(EventStoreClient::DeserializedEvent) }
      it 'has correct attributes' do
        aggregate_failures 'event attributes' do
          expect(subject.id).to eq(raw_event.id.string)
          expect(subject.title).to(
            eq("#{raw_event.stream_revision}@#{raw_event.stream_identifier.stream_name}")
          )
          expect(subject.type).to eq(raw_event.metadata['type'])
          expect(subject.data).to eq({})
          expect(subject.metadata).to include('type' => 'some-event')
          expect(subject.stream_revision).to eq(raw_event.stream_revision)
          expect(subject.commit_position).to eq(raw_event.commit_position)
          expect(subject.prepare_position).to eq(raw_event.prepare_position)
          expect(subject.stream_name).to eq(raw_event.stream_identifier.stream_name)
        end
      end

      context 'when raw_event#custom_metadata is present' do
        let(:data) { { 'foo' => 'bar' } }

        before do
          raw_event.custom_metadata = data.to_json
        end

        it 'includes it into #metadata of deserialized event' do
          expect(subject.metadata).to include(data)
        end
      end

      context 'when raw_event#data is present' do
        let(:data) { { 'foo' => 'bar' } }

        before do
          raw_event.data = data.to_json
        end

        it 'includes it into #data of deserialized event' do
          expect(subject.data).to eq(data)
        end
      end
    end

    describe 'when using default mapper' do
      let(:mapper) { EventStoreClient::Mapper::Default.new }

      before do
        EventStoreClient.config.mapper = mapper
        allow(mapper).to receive(:deserialize).and_call_original
      end

      it_behaves_like 'deserialized event'
      it 'deserializes event using it' do
        subject
        expect(mapper).to(
          have_received(:deserialize).with(
            instance_of(EventStoreClient::Event),
            skip_decryption: skip_decryption
          )
        )
      end
    end

    describe 'when using encrypted mapper' do
      let(:mapper) { EventStoreClient::Mapper::Encrypted.new(DummyRepository.new) }

      before do
        EventStoreClient.config.mapper = mapper
        allow(mapper).to receive(:deserialize).and_call_original
      end

      it_behaves_like 'deserialized event'
      it 'deserializes event using it' do
        subject
        expect(mapper).to(
          have_received(:deserialize).with(
            instance_of(EventStoreClient::Event),
            skip_decryption: skip_decryption
          )
        )
      end
    end
  end
end
