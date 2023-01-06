# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Read do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it 'uses correct params class' do
    expect(instance.request).to eq(EventStore::Client::Streams::ReadReq)
  end
  it 'uses correct service' do
    expect(instance.service).to be_a(EventStore::Client::Streams::Streams::Stub)
  end

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

    context 'when stream exists' do
      let(:data) { { foo: :bar } }
      let(:custom_metadata) { { created_at: created_at, transaction: 'some-trx' } }
      let(:created_at) { Time.at(10) }
      let(:event) do
        EventStoreClient::DeserializedEvent.new(
          id: SecureRandom.uuid,
          type: 'some-event',
          data: data,
          custom_metadata: custom_metadata
        )
      end

      before do
        EventStoreClient.client.append_to_stream(stream_name, event)
      end

      it 'reads events from stream' do
        aggregate_failures do
          is_expected.to be_an(Array)
          expect(subject.size).to eq(1)
        end
      end

      describe 'read event' do
        subject { super(); subject.first }

        it 'returns events of the given stream' do
          aggregate_failures do
            expect(subject.id).to eq(event.id)
            expect(subject.type).to eq(event.type)
            expect(subject.data).to eq('foo' => 'bar')
            expect(subject.metadata).to(
              match(
                'content-type' => 'application/json',
                'created' => instance_of(String),
                'type' => event.type
              )
            )
            expect(subject.custom_metadata).to(
              match(
                'transaction' => 'some-trx',
                'created_at' => created_at.to_s
              )
            )
          end
        end
      end

      context 'when skip_deserialization is false' do
        it 'returns deserialized event' do
          expect(subject.first).to be_a(EventStoreClient::DeserializedEvent)
        end
      end

      context 'when skip_deserialization is true' do
        let(:skip_deserialization) { true }

        it 'returns raw event' do
          expect(subject.first).to be_a(EventStore::Client::Streams::ReadResp)
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
            EventStoreClient::Mapper::Encrypted.new(DummyRepository.new, config: config)
          EventStoreClient.client.append_to_stream(stream_name, encrypted_event)
        end

        context 'when skip_decryption is false' do
          it 'returns decrypted event' do
            event = subject.find { |e| e.id == encrypted_event.id }
            expect(event.data).to(
              match(hash_including('first_name' => 'Anakin', 'last_name' => 'Skywalker'))
            )
          end
        end

        context 'when skip_decryption is true' do
          let(:skip_decryption) { true }

          it 'returns encrypted event' do
            event = subject.find { |e| e.id == encrypted_event.id }
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
          EventStoreClient.client.append_to_stream(stream_name, another_event)
        end

        describe 'reading events forward' do
          it 'reads events in ascending order' do
            aggregate_failures do
              expect(subject.first.id).to eq(event.id)
              expect(subject.last.id).to eq(another_event.id)
            end
          end
        end

        describe 'reading events backward' do
          let(:options) { { direction: 'Backwards', from_revision: :end } }

          it 'reads events in descending order' do
            aggregate_failures do
              expect(subject.first.id).to eq(another_event.id)
              expect(subject.last.id).to eq(event.id)
            end
          end
        end

        describe 'reading event starting from specific revision' do
          let(:options) { { from_revision: 1 } }

          it 'returns events starting from the given revision' do
            aggregate_failures do
              expect(subject.count).to eq(1)
              expect(subject.first.id).to eq(another_event.id)
            end
          end
        end

        context 'when :max_count option is given' do
          let(:options) { { max_count: 1 } }

          it 'limits the number of records in the result' do
            aggregate_failures do
              expect(subject.count).to eq(1)
              expect(subject.first.id).to eq(event.id)
            end
          end
        end
      end
    end

    context 'when resolve_link_tos option is true' do
      subject { super().first }

      let(:options) { { resolve_link_tos: true } }
      let(:another_stream_name) { "some-stream-1$#{SecureRandom.uuid}" }
      let(:event) do
        event = EventStoreClient::DeserializedEvent.new(
          type: 'some-event', data: { foo: :bar }
        )
        append_and_reload(another_stream_name, event)
      end

      before do
        EventStoreClient.client.link_to(stream_name, event)
      end

      it 'it returns linked event' do
        is_expected.to eq(event)
      end
    end

    describe 'reading from $all' do
      subject do
        instance.call(
          stream_name,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption
        )
      end

      let(:options) { { filter: { stream_identifier: { prefix: [stream_1, stream_2] } } } }
      let(:stream_name) { "$all" }
      let(:stream_1) { "some-stream-1$#{SecureRandom.uuid}" }
      let(:stream_2) { "some-stream-2$#{SecureRandom.uuid}" }
      let!(:events_stream_1) do
        2.times.map do
          event =
            EventStoreClient::DeserializedEvent.new(id: SecureRandom.uuid, type: 'some-event-1')
          append_and_reload(stream_1, event)
        end
      end
      let!(:events_stream_2) do
        3.times.map do
          event =
            EventStoreClient::DeserializedEvent.new(id: SecureRandom.uuid, type: 'some-event-2')
          append_and_reload(stream_2, event)
        end
      end

      it 'reads events from $all' do
        streams_in_result = subject.map(&:stream_name).uniq
        expect(streams_in_result).to match_array([stream_1, stream_2])
      end
      it 'returns correct result' do
        expect(subject).to match_array(events_stream_1 + events_stream_2)
      end
    end

    context 'when stream does not exist' do
      it 'raises error' do
        expect { subject }.to(
          raise_error(EventStoreClient::StreamNotFoundError, a_string_including(stream_name))
        )
      end
    end
  end
end
