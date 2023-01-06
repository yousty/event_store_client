# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Append do
  subject { instance.call(stream, event, options: options) }

  let(:client) { EventStoreClient::GRPC::Client.new(config) }
  let(:data) { { key1: 'value1', key2: 'value2' } }
  let(:metadata) { { 'transaction' => 'some-trx' } }
  let(:event) do
    EventStoreClient::DeserializedEvent.new(
      type: 'TestEvent', data: data, metadata: metadata
    )
  end
  let(:stream) { "stream$#{SecureRandom.uuid}" }
  let(:options) { {} }
  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.new(config: config) }

  it 'appends event to a stream' do
    expect { subject }.to change {
      client.read(
        '$all',
        options: { filter: { stream_identifier: { prefix: [stream] } } }
      ).count
    }.by(1)
  end
  it 'uses correct params class' do
    expect(instance.request).to eq(EventStore::Client::Streams::AppendReq)
  end
  it 'uses correct service' do
    expect(instance.service).to be_a(EventStore::Client::Streams::Streams::Stub)
  end

  context 'when expected revision does not match' do
    let(:options) { { expected_revision: 10 } }

    before do
      EventStoreClient.client.append_to_stream(stream, EventStoreClient::DeserializedEvent.new)
      EventStoreClient.client.append_to_stream(stream, EventStoreClient::DeserializedEvent.new)
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
        message = 'Stream revision 10 is expected, but actual stream revision is 1.'
        expect(subject.message).to eq(message)
      end
      it 'has info about current and expected revisions' do
        aggregate_failures do
          expect(subject.wrong_expected_version.current_revision).to eq(1)
          expect(subject.wrong_expected_version.expected_revision).to eq(options[:expected_revision])
        end
      end
    end
  end

  context 'when revision is :no_stream' do
    subject do
      first_event
      described_class.new(config: config).call(stream, event, options: options)
    end

    let(:first_event) do
      described_class.new(config: config).call(stream, another_event, options: options)
    end
    let(:another_event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
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
      described_class.new(config: config).call(stream, event, options: options)
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
