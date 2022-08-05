# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Client do
  let(:instance) { described_class.new }

  describe '#append_to_stream' do
    subject { instance.append_to_stream(stream_name, event, options: options) }

    let(:stream_name) { "stream_name$#{SecureRandom.uuid}" }
    let(:options) { { expected_revision: :no_stream } }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end
    let(:append_multiple_inst) { EventStoreClient::GRPC::Commands::Streams::AppendMultiple.new }
    let(:append_inst) { EventStoreClient::GRPC::Commands::Streams::Append.new }

    before do
      allow(EventStoreClient::GRPC::Commands::Streams::AppendMultiple).to(
        receive(:new).and_return(append_multiple_inst)
      )
      allow(EventStoreClient::GRPC::Commands::Streams::Append).to(
        receive(:new).and_return(append_inst)
      )
      allow(append_multiple_inst).to receive(:call).and_call_original
      allow(append_inst).to receive(:call).and_call_original
    end

    context 'when appending single event' do
      it 'calls append to stream command with correct arguments' do
        subject
        expect(append_inst).to have_received(:call).with(
          stream_name, event, options: options
        )
      end
      it { is_expected.to be_a(Dry::Monads::Success) }
    end

    context 'when appending multiple events' do
      subject do
        instance.append_to_stream(stream_name, [event], options: options)
      end

      it 'calls append to stream command with correct arguments' do
        subject
        expect(append_multiple_inst).to have_received(:call).with(
          stream_name, [event], options: options
        )
      end
      it { is_expected.to be_an(Array) }
      it { is_expected.to all be_a(Dry::Monads::Success) }
    end
  end

  describe '#read' do
    subject { instance.read(stream_name) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    before do
      EventStoreClient.client.append_to_stream(stream_name, event)
    end

    it 'returns events' do
      expect(subject.success).to all be_a EventStoreClient::DeserializedEvent
    end
    it { is_expected.to be_a(Dry::Monads::Success) }
  end

  describe '#read_paginated' do
    subject { instance.read_paginated('$all') }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    before do
      EventStoreClient.client.append_to_stream(stream_name, event)
    end

    it { is_expected.to be_a(Enumerator) }
    it 'returns events on #next' do
      expect(subject.next.success).to all be_a EventStoreClient::DeserializedEvent
    end
  end

  describe '#hard_delete_stream' do
    subject { instance.hard_delete_stream(stream_name) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    before do
      EventStoreClient.client.append_to_stream(stream_name, event)
    end

    it { is_expected.to be_a(Dry::Monads::Success) }
    it 'returns delete response' do
      expect(subject.success).to be_a(EventStore::Client::Streams::DeleteResp)
    end
  end

  describe '#clusted_info' do
    subject { instance.cluster_info }

    it 'returns cluster info' do
      expect(subject.success).to be_a(EventStore::Client::Gossip::ClusterInfo)
    end
  end
end

