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
      ).count
    }.by(2)
  end
  it 'returns append response' do
    is_expected.to all be_a(EventStore::Client::Streams::AppendResp)
  end

  context 'when expected revision does not match' do
    let(:options) { { expected_revision: 10 } }
    let(:requests) { [] }

    before do
      EventStoreClient.client.append_to_stream(stream, EventStoreClient::DeserializedEvent.new)
      allow(EventStoreClient::GRPC::Commands::Streams::Append).to receive(:new).
        and_wrap_original do |original_method, *args, **kwargs, &blk|
        instance = original_method.call(*args, **kwargs, &blk)
        allow(instance).to receive(:call).
          and_wrap_original do |original_method, *args, **kwargs, &blk|
          original_method.call(*args, **kwargs, &blk)
        ensure
          requests.push(:request)
        end
        instance
      end
    end

    it 'raises error' do
      expect { subject }.to raise_error(EventStoreClient::WrongExpectedVersionError)
    end
    it 'does not perform requests after first failure' do
      expect { subject rescue nil }.to change { requests.size }.by(1)
    end

    describe 'raised error' do
      subject do
        super()
      rescue => e
        e
      end

      it { is_expected.to be_a(EventStoreClient::WrongExpectedVersionError) }
      it 'has friendly message' do
        message = 'Stream revision 10 is expected, but actual stream revision is 0.'
        expect(subject.message).to eq(message)
      end
      it 'has info about current and expected revisions' do
        aggregate_failures do
          expect(subject.wrong_expected_version.current_revision).to eq(0)
          expect(subject.wrong_expected_version.expected_revision).to eq(options[:expected_revision])
        end
      end
    end
  end

  context 'when revision is :no_stream' do
    subject do
      first_event
      described_class.new(config: config).call(stream, [event2], options: options)
    end

    let(:first_event) do
      described_class.new(config: config).call(stream, [event1], options: options)
    end
    let(:options) { { expected_revision: :no_stream } }

    it 'accepts only one event' do
      expect { subject rescue nil }.to change {
        client.read(
          '$all',
          options: { filter: { stream_identifier: { prefix: [stream] } } }
        ).count
      }.by(1)
    end
    it 'raises error' do
      expect { subject }.to raise_error(EventStoreClient::WrongExpectedVersionError)
    end

    describe 'raised error' do
      subject do
        super()
      rescue => e
        e
      end

      it { is_expected.to be_a(EventStoreClient::WrongExpectedVersionError) }
      it 'has friendly message' do
        message = 'Expected stream to be absent, but it actually exists.'
        expect(subject.message).to eq(message)
      end
      it 'has info that the error is due to :no_stream' do
        expect(subject.wrong_expected_version.expected_no_stream).to be_a(EventStore::Client::Empty)
      end
    end
  end

  context 'when revision is :stream_exists' do
    subject do
      described_class.new(config: config).call(stream, [event1], options: options)
    end

    let(:options) { { expected_revision: :stream_exists } }

    it 'raises error' do
      expect { subject }.to raise_error(EventStoreClient::WrongExpectedVersionError)
    end

    describe 'raised error' do
      subject do
        super()
      rescue => e
        e
      end

      it { is_expected.to be_a(EventStoreClient::WrongExpectedVersionError) }
      it 'has friendly message' do
        message = "Expected stream to exist, but it doesn't."
        expect(subject.message).to eq(message)
      end
      it 'has info that the error is due to :stream_exists' do
        expect(subject.wrong_expected_version.expected_stream_exists).to(
          be_a(EventStore::Client::Empty)
        )
      end
    end
  end
end
