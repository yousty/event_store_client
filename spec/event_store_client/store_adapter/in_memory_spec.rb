# frozen_string_literal: true

module EventStoreClient
  RSpec.describe StoreAdapter::InMemory do
    subject { described_class.new(host: 'localhost', port: 2113) }
    describe '#append_to_stream' do
      it 'adds one event to a stream' do
        expect do
          subject.append_to_stream('sample_stream', something_happened)
        end.to change { subject.event_store['sample_stream']&.length }.
          from(nil).to(1)

        expect(subject.event_store['sample_stream']).to contain_exactly(
          hash_including(
            'eventId' => something_happened.id,
            'data' => something_happened.data,
            'eventType' => something_happened.type,
            'positionEventNumber' => 0
          )
        )
        metadata = JSON.parse(subject.event_store['sample_stream'].first['metaData'])
        expect(metadata['created_at']).not_to be_empty
        expect(metadata['bar']).to eq('foo')
      end

      it 'adds multiple events to a stream' do
        events = [something_happened, something_else_happened]
        expect do
          subject.append_to_stream('sample_stream', events)
        end.to change { subject.event_store['sample_stream']&.length }.from(nil).to(2)

        expect(subject.event_store['sample_stream']).to include(
          hash_including(
            'eventId' => something_else_happened.id,
            'data' => something_else_happened.data,
            'eventType' => something_else_happened.type,
            'positionEventNumber' => 1
          ),
          hash_including(
            'eventId' => something_happened.id,
            'data' => something_happened.data,
            'eventType' => something_happened.type,
            'positionEventNumber' => 0
          )
        )
      end
    end

    describe '#read_events_backward' do
      before do
        events = [something_happened, something_else_happened]
        subject.append_to_stream('sample_stream', events)
      end

      it 'returns empty array if there is no stream' do
        expect(
          subject.send(:read_stream_backward, 'nonexisting', start: 0)
        ).to be_empty
      end

      it 'returns events in proper order' do
        events = subject.send(:read_stream_backward, 'sample_stream', start: 10)['entries']
        expect(
          events.map { |event| event['positionEventNumber'] }
        ).to eq([1, 0])
      end

      context 'when a start is equal to 0' do
        it 'returns the oldest event' do
          events = subject.send(:read_stream_backward, 'sample_stream', start: 0)['entries']
          expect(events.count).to eq(1)
          expect(
            events.map { |event| event['positionEventNumber'] }
          ).to eq([0])
        end
      end

      context 'when a start is equal to head' do
        it 'returns events' do
          events = subject.send(:read_stream_backward, 'sample_stream', start: 'head')['entries']
          expect(
            events.map { |event| event['positionEventNumber'] }
          ).to eq([1, 0])
        end
      end
    end

    describe '#read_events_forward' do
      before do
        events = [something_happened, something_else_happened]
        subject.append_to_stream('sample_stream', events)
      end

      it 'returns empty array if there is no stream' do
        expect(
          subject.send(:read_stream_forward, 'nonexisting', start: 0)
        ).to be_empty
      end

      it 'returns events in proper order' do
        events = subject.send(:read_stream_forward, 'sample_stream', start: 0)['entries']
        expect(
          events.map { |event| event['positionEventNumber'] }
        ).to eq([1, 0])
      end

      context 'when a start is equal to a last event position' do
        it 'returns the newest event' do
          events = subject.send(:read_stream_forward, 'sample_stream', start: 1)['entries']
          expect(events.count).to eq(1)
          expect(
            events.map { |event| event['positionEventNumber'] }
          ).to eq([1])
        end
      end
    end

    describe '#link_to' do
      let(:stream_name) { 'sample_stream' }
      let(:events) { [something_happened] }

      before do
        allow_any_instance_of(StoreAdapter::InMemory).to receive(:append_to_stream).with(
          stream_name,
          events
        )
      end

      it 'invokes append event to stream' do
        expect_any_instance_of(StoreAdapter::InMemory).to receive(:append_to_stream).with(stream_name, events)

        subject.link_to(stream_name, events)
      end
    end

    describe '#delete_stream' do
      it 'adds one event to a stream' do
        subject.append_to_stream('sample_stream', something_happened)
        expect(subject.event_store).to have_key('sample_stream')

        subject.delete_stream('sample_stream')
        expect(subject.event_store).not_to have_key('sample_stream')
      end
    end

    let(:something_happened) do
      Event.new(
        type: 'SomethingHappened',
        data: JSON.generate(foo: 'bar'),
        metadata: JSON.generate(bar: 'foo')
      )
    end

    let(:something_else_happened) do
      Event.new(
        type: 'SomethingElseHappened',
        data: { foo: 'bar' }.to_json,
        metadata: { bar: 'foo' }.to_json
      )
    end

    it 'implmenetes the same methods as the Client' do
      client_methods = EventStoreClient::StoreAdapter::Api::Client.instance_methods(false).sort
      expect(subject.class.instance_methods(false).sort).to eq(client_methods)
    end
  end
end
