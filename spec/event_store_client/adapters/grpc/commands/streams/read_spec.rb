# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Read do
  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe '#call' do
    subject do
      instance.call(
        stream_name,
        options: options,
        skip_deserialization: skip_deserialization,
        skip_decryption: skip_decryption
      )
    end

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:options) { {} }
    let(:skip_deserialization) { false }
    let(:skip_decryption) { false }

    describe 'when stream exists' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(
          id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
        )
      end

      before do
        EventStoreClient.client.append_to_stream(stream_name, [event])
      end

      it 'reads events from stream' do
        is_expected.to be_a(Dry::Monads::Success)
      end

      describe 'read events' do
        subject { super(); subject.success }

        it 'returns events of the given stream' do
          aggregate_failures do
            expect(subject.size).to eq(1)
            expect(subject.first.id).to eq(event.id)
          end
        end
      end

      context 'when skip_deserialization is false' do
        it 'returns deserialized event' do
          expect(subject.success.first).to be_a(EventStoreClient::DeserializedEvent)
        end
      end

      context 'when skip_deserialization is true' do
        let(:skip_deserialization) { true }

        it 'returns raw event' do
          expect(subject.success.first).to be_a(EventStore::Client::Streams::ReadResp)
        end
      end

      describe 'encrypted event' do
        let(:encrypted_event) do
          EncryptedEvent.new(id: SecureRandom.uuid, type: 'some-event', data: data)
        end
        let(:data) do
          {
            'user_id' => SecureRandom.uuid,
            'first_name' => 'Anakin',
            'last_name' => 'Skywalker',
            'profession' => 'Jedi'
          }
        end

        before do
          EventStoreClient.config.mapper =
            EventStoreClient::Mapper::Encrypted.new(DummyRepository.new)
          EventStoreClient.client.append_to_stream(stream_name, [encrypted_event])
        end

        context 'when skip_decryption is false' do
          it 'returns decrypted event' do
            event = subject.success.find { |e| e.id == encrypted_event.id }
            expect(event.data).to match(hash_including('first_name' => 'Anakin', 'last_name' => 'Skywalker'))
          end
        end

        context 'when skip_decryption is true' do
          let(:skip_decryption) { true }

          it 'returns encrypted event' do
            event = subject.success.find { |e| e.id == encrypted_event.id }
            expect(event.data).to(
              match(hash_including('first_name' => 'es_encrypted', 'last_name' => 'es_encrypted'))
            )
          end
        end
      end

      describe 'several events' do
        let(:another_event) do
          EventStoreClient::DeserializedEvent.new(
            id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
          )
        end

        before do
          EventStoreClient.client.append_to_stream(stream_name, [another_event])
        end

        describe 'reading events forward' do
          it 'reads events in ascending order' do
            events = subject.success
            aggregate_failures do
              expect(events.first.id).to eq(event.id)
              expect(events.last.id).to eq(another_event.id)
            end
          end
        end

        describe 'reading events backward' do
          let(:options) { { direction: 'Backwards', from_revision: :end } }

          it 'reads events in descending order' do
            events = subject.success
            aggregate_failures do
              expect(events.first.id).to eq(another_event.id)
              expect(events.last.id).to eq(event.id)
            end
          end
        end

        describe 'reading event starting from specific revision' do
          let(:options) { { from_revision: 1 } }

          it 'returns events starting from the given revision' do
            events = subject.success
            aggregate_failures do
              expect(events.count).to eq(1)
              expect(events.first.id).to eq(another_event.id)
            end
          end
        end

        context 'when :max_count option is given' do
          let(:options) { { max_count: 1 } }

          it 'limits the number of records in the result' do
            events = subject.success
            aggregate_failures do
              expect(events.count).to eq(1)
              expect(events.first.id).to eq(event.id)
            end
          end
        end
      end
    end

    describe 'when stream does not exist' do
      it 'returns error' do
        is_expected.to be_a(Dry::Monads::Failure)
      end

      describe 'failure message' do
        subject { super().failure }

        it { is_expected.to eq(:stream_not_found) }
      end
    end
  end
end
