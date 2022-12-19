# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Shared::Streams::ProcessResponses do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }
  let(:mapper) { config.mapper }

  it { is_expected.to be_a(Dry::Monads::Result::Mixin) }

  describe '#call' do
    subject { instance.call(responses, skip_deserialization, skip_decryption) }

    let(:not_found_resp) do
      EventStore::Client::Streams::ReadResp.new(
        stream_not_found: { stream_identifier: { stream_name: 'some-stream' } }
      )
    end
    let(:responses) { [not_found_resp] }
    let(:skip_deserialization) { false }
    let(:skip_decryption) { false }

    context 'when stream is not found' do
      it { is_expected.to be_failure }
      it 'has proper error message' do
        expect(subject.failure).to eq(:stream_not_found)
      end
    end

    context 'when responses is empty' do
      let(:responses) { [] }

      it { is_expected.to be_success }
      it 'returns it' do
        expect(subject.success).to eq(responses)
      end
    end

    context 'when skip_deserialization is false' do
      let(:confirmation_resp) do
        EventStore::Client::Streams::ReadResp.new(confirmation: { subscription_id: 'some-id' })
      end
      let(:responses) { [confirmation_resp] }

      context 'when responses does not contain RecordedEvent' do
        it { is_expected.to be_success }
        it 'returns empty array' do
          expect(subject.success).to eq([])
        end
      end

      context 'when responses contain RecordedEvent' do
        let(:responses) do
          [confirmation_resp, event_resp]
        end
        let(:event_resp) do
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
        it 'returns only RecordedEvent-s in the result' do
          expect(subject.success.map(&:id)).to eq([recorded_event.id.string])
        end

        describe 'skip_decryption option' do
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

    context 'when skip_deserialization is true' do
      let(:confirmation_resp) do
        EventStore::Client::Streams::ReadResp.new(confirmation: { subscription_id: 'some-id' })
      end
      let(:responses) { [confirmation_resp] }
      let(:skip_deserialization) { true }

      it { is_expected.to be_success }
      it 'returns responses as is' do
        expect(subject.success).to eq(responses)
      end
    end
  end
end
