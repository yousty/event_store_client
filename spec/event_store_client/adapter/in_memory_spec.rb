# frozen_string_literal: true

module EventStoreClient
  RSpec.describe Adapter::InMemory do
    subject { described_class.new(host: 'localhost', port: 2113) }
    describe "#append_to_stream" do
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
        metadata = JSON.parse(subject.event_store['sample_stream'].first['metadata'])
        expect(metadata['created_at']).not_to be_empty
        expect(metadata['bar']).to eq('foo')
      end
    end

    it 'adds multiple events to a stream' do
      events = [something_happened, something_else_happened]
      expect {
        subject.append_to_stream('sample_stream', events)
      }.to change { subject.event_store['sample_stream']&.length }.from(nil).to(2)

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

    describe "#read_events_backward" do
      before do
        events = [something_happened, something_else_happened]
        subject.append_to_stream('sample_stream', events)
      end

      it 'returns empty array if there is no stream' do
        expect(
          subject.read_stream_backward('nonexisting', start: 0)
        ).to be_empty
      end

      it 'returns events in proper order' do
        events = subject.read_stream_backward('sample_stream', start: 0)['entries']
        expect(
          events.map { |event| event['positionEventNumber'] }
        ).to eq([1, 0])
      end
    end

    describe "#read_events_forward" do
      before do
        events = [something_happened, something_else_happened]
        subject.append_to_stream('sample_stream', events)
      end

      it 'returns empty array if there is no stream' do
        expect(
          subject.read_stream_forward('nonexisting', start: 0)
        ).to be_empty
      end

      it 'returns events in proper order' do
        events = subject.read_stream_forward('sample_stream', start: 0)['entries']
        expect(
          events.map { |event| event['positionEventNumber'] }
        ).to eq([0, 1])
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
  end
end