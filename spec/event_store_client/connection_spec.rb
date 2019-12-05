# frozen_string_literal: true

module EventStoreClient
  RSpec.describe Connection do
    let(:client) do
      EventStoreClient::StoreAdapter::Api::Client.new(host: 'https://example.com', port: 8080)
    end
    let(:connection) { described_class.new }
    let(:event) { SomethingHappened.new(data: { foo: 'bar' }, metadata: {}) }

    describe '#publish' do
      before do
        allow_any_instance_of(EventStoreClient::StoreAdapter::Api::Client).
          to receive(:append_to_stream)
      end

      it 'returns serialized events' do
        serialized_event = connection.publish(stream: 'stream', events: [event]).first
        expect(JSON.parse(serialized_event.data)).to include('foo' => 'bar')
        expect(serialized_event.type).to eq('EventStoreClient::SomethingHappened')
      end
    end

    describe '#read' do; end

    describe '#subscribe' do
      it 'invokes the subscribe_to_stream method' do
        allow_any_instance_of(EventStoreClient::StoreAdapter::Api::Client).
          to receive(:subscribe_to_stream).with('stream', 'subscription').and_return(true)

        expect(connection.subscribe('stream', name: 'subscription')).to be_truthy
      end
    end

    describe '#consume_feed' do; end
  end
end
