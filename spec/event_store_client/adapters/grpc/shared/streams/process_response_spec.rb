# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Shared::Streams::ProcessResponse do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }
  let(:mapper) { config.mapper }

  it { is_expected.to be_a(Dry::Monads::Result::Mixin) }

  describe '#call' do
    subject { instance.call(response, skip_deserialization, skip_decryption) }

    let(:response) do
      EventStore::Client::Streams::ReadResp.new(
        stream_not_found: { stream_identifier: { stream_name: 'some-stream' } }
      )
    end
    let(:skip_deserialization) { false }
    let(:skip_decryption) { false }

    context 'when stream is not found' do
      it { is_expected.to be_failure }
      it 'has proper error message' do
        expect(subject.failure).to eq(:stream_not_found)
      end
    end

    context 'when response is not a RecordedEvent' do
      let(:response) do
        EventStore::Client::Streams::ReadResp.new(confirmation: { subscription_id: 'some-id' })
      end

      context 'when skip_deserialization is false' do
        it { is_expected.to be_nil }
      end

      context 'when skip_deserialization is true' do
        let(:skip_deserialization) { true }

        it { is_expected.to be_success }
        it 'returns response as it is' do
          expect(subject.success).to eq(response)
        end
      end
    end

    context 'when response is a RecordedEvent' do
      let(:response) do
        EventStore::Client::Streams::ReadResp.new(event: { event: recorded_event})
      end
      let(:recorded_event) do
        EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent.new(
          id: EventStore::Client::UUID.new(string: 'some-id'),
          stream_identifier: { stream_name: 'some-stream' },
          metadata: { type: 'some-event' }
        )
      end

      it { is_expected.to be_success }
      it 'returns deserialized event' do
        expect(subject.success).to be_a(EventStoreClient::DeserializedEvent)
      end

      context 'when skip_decryption is true' do
        let(:skip_decryption) { true }

        before do
          allow(mapper).to receive(:deserialize).and_call_original
        end

        it 'takes it into account' do
          subject
          expect(mapper).to(
            have_received(:deserialize).with(recorded_event, skip_decryption: skip_decryption)
          )
        end
      end
    end
  end
end
