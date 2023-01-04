# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::ReadPaginated do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }

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

    it { is_expected.to be_a(Enumerator) }

    context 'when :max_count option is less than 2' do
      let(:options) { { max_count: 1 } }

      it 'raises error' do
        expect { subject.next }.to raise_error(described_class::RecordsLimitError)
      end
    end

    context 'when stream does not exist' do
      it 'raises error' do
        expect { subject.next }.to(
          raise_error(EventStoreClient::StreamNotFoundError, a_string_including(stream_name))
        )
      end
    end

    context 'when stream exists' do
      let!(:events) do
        10.times.map do
          event = EventStoreClient::DeserializedEvent.new(id: SecureRandom.uuid, type: 'some-event')
          append_and_reload(stream_name, event)
        end
      end
      let(:options) { { max_count: 9 } }

      context 'when number of events is greater than or equal to :max_count option' do
        it 'returns correct result on first iteration' do
          expect(subject.next).to eq(events.first(9))
        end
        it 'returns correct result on next iteration' do
          subject.next
          expect(subject.next).to eq([events.last])
        end
      end

      context 'when number of events is less than or equal to :max_count option' do
        let(:options) { { max_count: 100 } }

        it 'returns all of them in first iteration' do
          expect(subject.next).to eq(events)
        end
      end

      context 'fetching events from the given revision' do
        let(:options) { { max_count: 100, from_revision: 8 } }

        it 'returns events from the given revision' do
          expect(subject.next).to eq(events[8..])
        end
      end
    end

    describe 'paginating $all stream' do
      subject do
        instance.call(
          stream_name,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption
        )
      end

      let(:options) { { filter: { stream_identifier: { prefix: [some_stream] } } } }
      let(:stream_name) { "$all" }
      let(:some_stream) { "some-stream-1$#{SecureRandom.uuid}" }
      let!(:events) do
        10.times.map do
          event = EventStoreClient::DeserializedEvent.new(type: 'some-event')
          append_and_reload(some_stream, event)
        end
      end

      context 'fetching events from the given position' do
        let(:options) do
          super().merge(
            max_count: 100,
            from_position: {
              # Take commit_position of second event from the end
              commit_position: events.last(2).first.commit_position
            }
          )
        end

        it 'returns events from the given position' do
          expect(subject.next).to eq(events[8..])
        end
      end
    end

    describe 'paginating projection' do
      subject do
        instance.call(
          stream_name,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption
        )
      end

      let(:options) { { resolve_link_tos: true, max_count: 3 } }
      let(:stream_name) { "some-projection$#{SecureRandom.uuid}" }
      let!(:events) do
        10.times.map do
          event = EventStoreClient::DeserializedEvent.new(id: SecureRandom.uuid, type: 'some-event')
          stream_name = "some-stream$#{SecureRandom.uuid}"
          append_and_reload(stream_name, event)
        end
      end

      before do
        EventStoreClient.client.link_to(stream_name, events)
      end

      it 'returns all events' do
        result = nil
        worker = Thread.new { result = subject.to_a.flatten }
        sleep 1
        worker.kill
        error_message = <<~TEXT
          Failed to correctly paginate the projection. \
          Expected paginated read to return 10 events. Got #{result.inspect}. It seems it trapped \
          into an infinite loop.
        TEXT
        expect(result).to eq(events), error_message
      end
    end
  end
end
