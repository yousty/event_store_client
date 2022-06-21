# frozen_string_literal: true

require 'spec_helper'
require 'event_store_client/adapters/grpc/commands/streams/append'

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Append do
  subject { described_class.new.call(stream, events, options: options) }

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

  it 'appends events to a stream' do
    subject
    expect(client.read(stream).value!.count).to eq(2)
  end

  it 'returns Success' do
    expect(subject).to eq(Success())
  end

  context 'when expected version does not match' do
    let(:options) { { expected_version: 10 } }
    let(:failure_message) { 'current version: 0 | expected: 10' }

    it 'returns failure' do
      expect(subject).to eq(Failure(failure_message))
    end
  end

  # move to lower level
  context 'in case the eventstore is down' do
    let(:failure_message) { 'failed to connect to eventstore' }

    before do
      EventStoreClient.config.eventstore_url = 'localhost:1234'
    end

    after do
      EventStoreClient.config.eventstore_url = ENV['EVENTSTORE_URL']
    end

    it 'returns failure' do
      expect(subject.failure.class).to be(GRPC::Unavailable)
    end
  end
end
