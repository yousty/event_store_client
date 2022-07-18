# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::AppendMultiple do
  subject { instance.call(stream, events, options: options) }

  let(:client) { EventStoreClient::GRPC::Client.new }
  let(:data) { { key1: 'value1', key2: 'value2' } }
  let(:metadata1) { { key1: 'value1', key2: 'value2', type: 'TestEvent', 'content-type' => 'test' } }
  let(:metadata2) { { type: 'TestEvent2', 'content-type' => 'test'} }
  let(:event1) {
    EventStoreClient::Event.new(type: 'TestEvent', data: data.to_json, metadata: metadata1.to_json)
  }
  let(:event2) { EventStoreClient::Event.new(type: 'TestEvent2', metadata: metadata2.to_json) }
  let(:events) { [event1, event2] }
  let(:stream) { "stream$#{SecureRandom.uuid}" }
  let(:options) { {} }
  let(:instance) { described_class.new }

  it 'appends events to a stream' do
    subject
    expect(client.read(stream).value!.count).to eq(2)
  end
  it 'returns Success' do
    expect(subject).to all be_a(Dry::Monads::Success)
  end

  context 'when expected revision does not match' do
    let(:options) { { expected_revision: 10 } }
    let(:failure_message) { 'current version: 0 | expected: 10' }

    it 'returns failure' do
      expect(subject).to all be_a(Dry::Monads::Failure)
    end
    it 'does not perform requests after first failure' do
      expect(subject.size).to eq(1)
    end

    describe 'failure' do
      subject { super().first.failure }

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
      described_class.new.call(stream, [event2], options: options)
    end

    let(:first_event) { described_class.new.call(stream, [event1], options: options) }
    let(:options) { { expected_revision: :no_stream } }

    it 'accepts only one event' do
      subject
      expect(client.read(stream).value!.count).to eq(1)
    end
    it 'returns failure' do
      expect(subject).to all be_a(Dry::Monads::Failure)
    end

    describe 'failure' do
      subject { super().first.failure }

      it { is_expected.to be_a(EventStore::Client::Streams::AppendResp::WrongExpectedVersion) }
      it 'has info that the error is due to :no_stream' do
        expect(subject.expected_no_stream).to be_a(EventStore::Client::Empty)
      end
    end
  end

  context 'when revision is :stream_exists' do
    subject do
      described_class.new.call(stream, [event1], options: options)
    end

    let(:options) { { expected_revision: :stream_exists } }

    it 'returns failure' do
      expect(subject).to all be_a(Dry::Monads::Failure)
    end

    describe 'failure' do
      subject { super().first.failure }

      it { is_expected.to be_a(EventStore::Client::Streams::AppendResp::WrongExpectedVersion) }
      it 'has info that the error is due to :stream_exists' do
        expect(subject.expected_stream_exists).to be_a(EventStore::Client::Empty)
      end
    end
  end

  # move to lower level
  context 'in case the eventstore is down' do
    let(:failure_message) { 'failed to connect to eventstore' }

    before do
      allow(EventStoreClient.config).to receive(:eventstore_url).and_return(URI('localhost:1234'))
    end

    it 'returns failure' do
      expect(subject.map(&:failure)).to all be_a(GRPC::Unavailable)
    end
  end
end
