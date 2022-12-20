# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Client do
  let(:instance) { described_class.new(config) }
  let(:config) { EventStoreClient.config }

  describe '#append_to_stream' do
    subject { instance.append_to_stream(stream_name, event, options: options) }

    let(:stream_name) { "stream_name$#{SecureRandom.uuid}" }
    let(:options) { { expected_revision: :no_stream } }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end
    let(:append_multiple_inst) do
      EventStoreClient::GRPC::Commands::Streams::AppendMultiple.new(config: config)
    end
    let(:append_inst) do
      EventStoreClient::GRPC::Commands::Streams::Append.new(config: config)
    end

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

  describe '#delete_stream' do
    subject { instance.delete_stream(stream_name) }

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

  describe '#subscribe_to_stream' do
    subject { Thread.new { instance.subscribe_to_stream(stream_name, handler: handler) } }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:handler) do
      proc { |response| responses.push(response) }
    end
    let(:responses) { [] }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    after do
      subject.kill
    end

    it 'triggers handler when new event arrives' do
      subject
      sleep 0.5
      expect {
        EventStoreClient.client.append_to_stream(stream_name, event)
        sleep 0.5
      }.to change { responses.size }.by(1)
    end
  end

  describe '#subscribe_to_all' do
    subject do
      Thread.new do
        instance.subscribe_to_stream('$all', handler: handler, options: options)
      end
    end

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:handler) do
      proc { |response| responses.push(response) }
    end
    let(:options) { { filter: { stream_identifier: { prefix: [stream_name] } } } }
    let(:responses) { [] }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    after do
      subject.kill
    end

    it 'triggers handler when new event arrives' do
      subject
      sleep 0.5
      expect {
        EventStoreClient.client.append_to_stream(stream_name, event)
        sleep 0.5
      }.to change { responses.size }.by(1)
    end
  end

  describe '#link_to' do
    subject { instance.link_to(stream_name, event, options: options) }

    let(:stream_name) { "stream_name$#{SecureRandom.uuid}" }
    let(:other_stream_name) { "other-stream$#{SecureRandom.uuid}" }
    let(:options) { {} }
    let(:event) do
      event = EventStoreClient::DeserializedEvent.new(type: 'some-event', data: { foo: :bar })
      EventStoreClient.client.append_to_stream(other_stream_name, event)
      EventStoreClient.client.read(other_stream_name).success.first
    end
    let(:link_multiple_inst) do
      EventStoreClient::GRPC::Commands::Streams::LinkToMultiple.new(config: config)
    end
    let(:link_inst) do
      EventStoreClient::GRPC::Commands::Streams::LinkTo.new(config: config)
    end

    before do
      allow(EventStoreClient::GRPC::Commands::Streams::LinkToMultiple).to(
        receive(:new).and_return(link_multiple_inst)
      )
      allow(EventStoreClient::GRPC::Commands::Streams::LinkTo).to(
        receive(:new).and_return(link_inst)
      )
      allow(link_multiple_inst).to receive(:call).and_call_original
      allow(link_inst).to receive(:call).and_call_original
    end

    context 'when linking single event' do
      it 'calls link command with correct arguments' do
        subject
        expect(link_inst).to have_received(:call).with(
          stream_name, event, options: options
        )
      end
      it { is_expected.to be_a(Dry::Monads::Success) }
      it 'returns append response' do
        expect(subject.success).to be_a(EventStore::Client::Streams::AppendResp)
      end
    end

    context 'when linking multiple events' do
      subject do
        instance.link_to(stream_name, [event], options: options)
      end

      it 'calls link command with correct arguments' do
        subject
        expect(link_multiple_inst).to have_received(:call).with(
          stream_name, [event], options: options
        )
      end
      it { is_expected.to be_an(Array) }
      it { is_expected.to all be_a(Dry::Monads::Success) }
      it 'returns append responses' do
        expect(subject.map(&:success)).to all be_a(EventStore::Client::Streams::AppendResp)
      end
    end
  end

  describe '#clusted_info' do
    subject { instance.cluster_info }

    it 'returns cluster info' do
      expect(subject.success).to be_a(EventStore::Client::Gossip::ClusterInfo)
    end
  end
end
