# frozen_string_literal: true

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
      before do
        events = [
          Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json),
          Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
        ]
        store_adapter.append_to_stream('stream', events)
      end

      context 'forward' do
        it 'reads events from the store', pending: true do
          pending('missing implementation of EventStoreClient::StoreAdapter::InMemory#read')
          events = client.read('stream', direction: 'forward')
          expect(events[0].type).to eq('SomethingHappened')
          expect(events[1].type).to eq('SomethingElseHappened')
        end
      end

      context 'backward' do
        it 'reads events from the store', pending: true do
          pending('missing implementation of EventStoreClient::StoreAdapter::InMemory#read')
          events = client.read('stream', direction: 'backard')
          expect(events[0].type).to eq('SomethingElseHappened')
          expect(events[1].type).to eq('SomethingHappened')
        end
      end
    end

    describe 'subscribe' do
    end

    describe 'pool' do
    end

    describe '#stop_polling' do
    end
  end
end
