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

    describe '#read' do
      let(:in_memory) do
        EventStoreClient::StoreAdapter::InMemory.new(
          host: 'https://example.com', port: 8080, per_page: 2
        )
      end
      let(:something_happened_1) do
        Event.new(
          type: 'SomethingHappened1',
          data: JSON.generate(foo: 'bar'),
          metadata: JSON.generate(bar: 'foo')
        )
      end
      let(:something_happened_2) do
        Event.new(
          type: 'SomethingHappened2',
          data: JSON.generate(foo: 'bar'),
          metadata: JSON.generate(bar: 'foo')
        )
      end
      let(:something_happened_3) do
        Event.new(
          type: 'SomethingHappened3',
          data: JSON.generate(foo: 'bar'),
          metadata: JSON.generate(bar: 'foo')
        )
      end

      before do
        in_memory.append_to_stream(
          'stream', [something_happened_1, something_happened_2, something_happened_3]
        )
        allow_any_instance_of(described_class).to receive(:client).and_return(in_memory)
        allow_any_instance_of(described_class).to receive(:per_page).and_return(2)
      end

      context 'forward' do
        context 'when a count is equal to 2' do
          it 'returns two first events in order from the oldest to the latest' do
            events =
              connection.read('stream', direction: 'forward', start: 0, all: false)
            expect(events.count).to eq(2)
            expect(events.map { |event| event.type }).
              to eq(['SomethingHappened1', 'SomethingHappened2'])
          end
        end
      end

      context 'backward' do
        context 'when a count is eqaul to 2 and start is equal to head' do
          it 'returns two last events in order from the oldest to the latest' do
            events =
              connection.read('stream', direction: 'backward', start: 'head', all: false)
            expect(events.count).to eq(2)
            expect(events.map { |event| event.type }).
              to eq(['SomethingHappened2', 'SomethingHappened3'])
          end
        end
      end

      context 'all' do
        it 'returns all evens in order from the oldest to the latest' do
          events =
            connection.read('stream', direction: 'forward', start: 0, all: true)
          expect(events.count).to eq(3)
          expect(events.map { |event| event.type }).
            to eq(['SomethingHappened1', 'SomethingHappened2', 'SomethingHappened3'])
        end
      end
    end

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
