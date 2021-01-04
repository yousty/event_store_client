# frozen_string_literal: true

module EventStoreClient
  RSpec.describe Client do
    let(:client) { described_class.new }
    let(:event) { SomethingHappened.new(data: { foo: 'bar' }, metadata: {}) }

    let(:store_adapter) { EventStoreClient.adapter }

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
        it 'reads events from a stream' do
          events = client.read('stream')
          expect(events.count).to eq(2)
          expect(events.map(&:type)).
            to eq(%w[SomethingHappened SomethingElseHappened])
        end
      end

      context 'backward' do
        it 'reads events from a stream' do
          events = client.read('stream', direction: 'backard', start: 'head')
          expect(events.count).to eq(2)
          expect(events.map(&:type)).
            to eq(%w[SomethingHappened SomethingElseHappened])
        end
      end

      context 'all' do
        it 'reads all events from a stream' do
          events = client.read('stream', all: true)
          expect(events.count).to eq(2)
          expect(events.map(&:type)).
            to eq(%w[SomethingHappened SomethingElseHappened])
        end
      end
    end

    describe '#link_to' do
      subject { -> { client.link_to(stream: stream_name, events: events) } }

      let(:event_1) { Event.new(type: 'SomethingHappened', data: {}.to_json) }
      let(:stream_name) { :stream_name }
      let(:events) { [event_1] }

      before do
        allow_any_instance_of(InMemory).to receive(:link_to).with(
          stream_name,
          events,
          expected_version: nil
        ).and_return(Success())
      end

      shared_examples 'argument error' do
        it 'raises an Argument error' do
          expect { subject.call }.to raise_error(ArgumentError)
        end
      end

      shared_examples 'correct linking events' do
        it 'invokes link event for the store' do
          expect_any_instance_of(InMemory).to receive(:link_to).with(
            stream_name,
            events,
            expected_version: nil
          )

          subject.call
        end

        it 'returns events' do
          expect(subject.call).to be_truthy
        end
      end

      context 'when missing stream' do
        let(:stream_name) { nil }
        it_behaves_like 'argument error'
      end

      context 'when missing events' do
        let(:events) { [] }
        it_behaves_like 'argument error'
      end

      context 'when passed single event' do
        let(:events) { event_1 }
        it_behaves_like 'correct linking events'
      end

      it_behaves_like 'correct linking events'
    end

    describe 'subscribe' do
    end
  end
end
