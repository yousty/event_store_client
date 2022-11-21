# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Append do
  subject { instance.call(stream, event, options: options) }

  let(:client) { EventStoreClient::GRPC::Client.new }
  let(:data) { { key1: 'value1', key2: 'value2' } }
  let(:metadata) { { 'transaction' => 'some-trx' } }
  let(:event) {
    EventStoreClient::DeserializedEvent.new(
      type: 'TestEvent', data: data, metadata: metadata
    )
  }
  let(:stream) { "stream$#{SecureRandom.uuid}" }
  let(:options) { {} }
  let(:instance) { described_class.new }

  it 'appends event to a stream' do
    expect { subject }.to change {
      client.read(
        '$all',
        options: { filter: { stream_identifier: { prefix: [stream] } } }
      ).success.count
    }.by(1)
  end
  it 'returns Success' do
    expect(subject).to be_a(Dry::Monads::Success)
  end
  it 'uses correct params class' do
    expect(instance.request).to eq(EventStore::Client::Streams::AppendReq)
  end
  it 'uses correct service' do
    expect(instance.service).to be_a(EventStore::Client::Streams::Streams::Stub)
  end

  context 'when expected revision does not match' do
    let(:options) { { expected_revision: 10 } }
    let(:failure_message) { 'current version: 0 | expected: 10' }

    it 'returns failure' do
      expect(subject).to be_a(Dry::Monads::Failure)
    end

    describe 'failure' do
      subject { super().failure }

      it { is_expected.to be_a(EventStore::Client::Streams::AppendResp::WrongExpectedVersion) }
      it 'has info about current and expected revisions' do
        aggregate_failures do
          expect(subject.current_revision).to eq(0)
          expect(subject.expected_revision).to eq(options[:expected_revision])
        end
      end
    end
  end

  context 'when revision is :no_stream' do
    subject do
      first_event
      described_class.new.call(stream, event, options: options)
    end

    let(:first_event) { described_class.new.call(stream, another_event, options: options) }
    let(:another_event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end
    let(:options) { { expected_revision: :no_stream } }

    it 'accepts only one event' do
      subject
      expect(client.read(stream).value!.count).to eq(1)
    end
    it 'returns failure' do
      expect(subject).to be_a(Dry::Monads::Failure)
    end

    describe 'failure' do
      subject { super().failure }

      it { is_expected.to be_a(EventStore::Client::Streams::AppendResp::WrongExpectedVersion) }
      it 'has info that the error is due to :no_stream' do
        expect(subject.expected_no_stream).to be_a(EventStore::Client::Empty)
      end
    end
  end

  context 'when revision is :stream_exists' do
    subject do
      described_class.new.call(stream, event, options: options)
    end

    let(:options) { { expected_revision: :stream_exists } }

    it 'returns failure' do
      expect(subject).to be_a(Dry::Monads::Failure)
    end

    describe 'failure' do
      subject { super().failure }

      it { is_expected.to be_a(EventStore::Client::Streams::AppendResp::WrongExpectedVersion) }
      it 'has info that the error is due to :stream_exists' do
        expect(subject.expected_stream_exists).to be_a(EventStore::Client::Empty)
      end
    end
  end
end
