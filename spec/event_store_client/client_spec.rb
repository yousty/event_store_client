# frozen_string_literal: true

require_relative './event_store_helpers'

module EventStoreClient
  RSpec.describe Client do
    let(:client) { described_class.new }
    let(:event) { SomethingHappened.new(data: { foo: 'bar' }, metadata: {}) }
    let(:store_adapter) { StoreAdapter::InMemory.new(host: 'localhost', port: '2013') }

    before do
      allow_any_instance_of(Connection).to receive(:client).and_return(store_adapter)
    end

    describe '#publish' do
      it 'publishes events to the store' do
        client.publish(stream: 'stream', events: [event])
        expect(store_adapter.event_store['stream'].length).to eq(1)
        client.publish(stream: 'stream', events: [event])
        expect(store_adapter.event_store['stream'].length).to eq(2)
      end
    end

    describe '#read' do
    end

    describe 'subscribe' do
    end

    describe 'poll' do
    end

    describe '#stop_polling' do
    end
  end
end
