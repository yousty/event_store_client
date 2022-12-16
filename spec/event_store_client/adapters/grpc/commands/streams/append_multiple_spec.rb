# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::AppendMultiple do
  subject { instance.call(stream, events, options: options) }

  let(:client) { EventStoreClient::GRPC::Client.new(config) }
  let(:data) { { key1: 'value1', key2: 'value2' } }
  let(:metadata1) { { key1: 'value1', key2: 'value2', type: 'TestEvent', 'content-type' => 'test' } }
  let(:metadata2) { { type: 'TestEvent2', 'content-type' => 'test'} }
  let(:event1) {
    EventStoreClient::DeserializedEvent.new(
      type: 'TestEvent', data: data, metadata: metadata1
    )
  }
  let(:event2) { EventStoreClient::DeserializedEvent.new(type: 'TestEvent2', metadata: metadata2) }
  let(:events) { [event1, event2] }
  let(:stream) { "stream$#{SecureRandom.uuid}" }
  let(:options) { {} }
  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.new(config: config) }

  it 'appends events to a stream' do
    expect { subject }.to change {
      client.read(
        '$all',
        options: { filter: { stream_identifier: { prefix: [stream] } } }
      ).success.count
    }.by(2)
  end
  it 'returns Success' do
    expect(subject).to all be_a(Dry::Monads::Success)
  end

  context 'when expected revision does not match' do
    let(:options) { { expected_revision: 10 } }
    let(:requests) { [] }

    before do
      allow(EventStoreClient::GRPC::Commands::Streams::Append).to receive(:new).
        and_wrap_original do |original_method, *args, **kwargs, &blk|
        instance = original_method.call(*args, **kwargs, &blk)
        allow(instance).to receive(:call).
          and_wrap_original do |original_method, *args, **kwargs, &blk|
          result = original_method.call(*args, **kwargs, &blk)
          requests.push(:request)
          result
        end
        instance
      end
    end

    it 'returns failure' do
      expect(subject).to all be_a(Dry::Monads::Failure)
    end
    it 'does not perform requests after first failure' do
      expect { subject }.to change { requests.size }.by(1)
    end
    it 'accumulates first failure' do
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
      described_class.new(config: config).call(stream, [event2], options: options)
    end

    let(:first_event) { described_class.new(config: config).call(stream, [event1], options: options) }
    let(:options) { { expected_revision: :no_stream } }

    it 'accepts only one event' do
      expect { subject }.to change {
        client.read(
          '$all',
          options: { filter: { stream_identifier: { prefix: [stream] } } }
        ).success.count
      }.by(1)
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
      described_class.new(config: config).call(stream, [event1], options: options)
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
end
