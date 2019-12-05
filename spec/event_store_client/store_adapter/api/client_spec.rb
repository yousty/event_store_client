# frozen_string_literal: true

module EventStoreClient::StoreAdapter::Api
  RSpec.describe Client do
    let(:api_client) { described_class.new(host: 'https://www.example.com', port: 8080) }

    describe '#append_to_stream' do
      let(:event_1) do
        EventStoreClient::Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json)
      end
      let(:event_2) do
        EventStoreClient::Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
      end
      let(:body) do
        [event_1, event_2].map do |event|
          {
            eventId: event.id,
            eventType: event.type,
            data: event.data,
            metadata: event.metadata
          }
        end
      end
      let!(:stub) do
        stub_request(:post, 'https://www.example.com:8080/streams/stream_name').
          with(headers: { 'ES-ExpectedVersion': '0' }, body: body.to_json)
      end

      it 'sends a correct request' do
        events = [event_1, event_2]
        api_client.append_to_stream('stream_name', events, expected_version: 0)
        expect(stub).to have_been_requested
      end
    end

    describe '#delete_stream' do
      let!(:stub) do
        stub_request(:delete, 'https://www.example.com:8080/streams/stream_name').
          with(headers: { 'ES-HardDelete': 'true' })
      end

      it 'sends a correct request' do
        api_client.delete_stream('stream_name', true)
        expect(stub).to have_been_requested
      end
    end

    describe '#read' do
      let!(:stub) do
        stub_request(
          :get,
          'https://www.example.com:8080/streams/stream_name/0/forward/20?embed=body'
        ).with(headers: { 'Content-Type': 'application/vnd.eventstore.events+json' })
      end

      it 'sends a correct request' do
        api_client.read('stream_name', count: 20)
        expect(stub).to have_been_requested
      end
    end

    describe '#subscribe_to_stream' do
      let(:body) { { extraStatistics: true, startFrom: 0, maxRetryCount: 5, resolveLinkTos: true } }
      let!(:stub) do
        stub_request(
          :put,
          'https://www.example.com:8080/subscriptions/stream_name/subscription_name'
        ).with(
          headers: { 'Content-Type': 'application/json' },
          body: body.to_json
        )
      end

      it 'sends a correct request' do
        api_client.subscribe_to_stream(
          'stream_name', 'subscription_name', stats: true, start_from: 0, retries: 5
        )
        expect(stub).to have_been_requested
      end
    end

    describe '#consume_feed' do
      let!(:stub) do
        stub_request(
          :get,
          'https://www.example.com:8080/subscriptions/stream_name/subscription_name/10?embed=body'
        ).with(
          headers: {
            'Content-Type': 'application/vnd.eventstore.competingatom+json',
            'Accept': 'application/vnd.eventstore.competingatom+json',
            'ES-LongPoll': '5'
          }
        )
      end

      it 'sends a correct request' do
        api_client.consume_feed('stream_name', 'subscription_name', count: 10, long_poll: 5)
        expect(stub).to have_been_requested
      end
    end
  end
end
