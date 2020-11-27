# frozen_string_literal: true

module EventStoreClient::StoreAdapter::Api
  RSpec.describe Client do
    let(:mapper) { EventStoreClient::Mapper::Default.new }
    let(:api_client) { described_class.new(host: 'https://www.example.com', port: 8080, mapper: mapper) }

    let(:stream_name) { :stream_name }
    let(:events) { [event_1, event_2] }

    describe '#append_to_stream' do
      let(:event_1) do
        EventStoreClient::Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json)
      end
      let(:event_2) do
        EventStoreClient::Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
      end
      let(:body) do
        events.map do |event|
          {
            eventId: event.id,
            eventType: event.type,
            data: event.data,
            metadata: event.metadata
          }
        end
      end
      let!(:stub) do
        stub_request(:post, stream_url(stream_name)).
          with(headers: { 'ES-ExpectedVersion': '0' }, body: body.to_json)
      end
      let!(:invalid_request_stub) do
        stub_request(:post, stream_url(stream_name)).
          with(headers: { 'ES-ExpectedVersion': '10' }, body: body.to_json).
          to_return(
            status: [400, 'Wrong expected EventNumber'],
            headers: { 'es-currentversion': 0 }
          )
      end

      it 'sends a correct request' do
        api_client.append_to_stream(stream_name, events, expected_version: 0)
        expect(stub).to have_been_requested
      end

      it 'raises exception when passed a wrong expected wersion' do
        expect { api_client.append_to_stream(stream_name, events, expected_version: 10) }.
          to raise_error(
            EventStoreClient::StoreAdapter::Api::Client::WrongExpectedEventVersion,
            'current version: 0 | expected: 10'
          )
      end
    end

    describe '#delete_stream' do
      let!(:stub) do
        stub_request(:delete, stream_url(stream_name)).
          with(headers: { 'ES-HardDelete': 'true' })
      end

      it 'sends a correct request' do
        api_client.delete_stream(stream_name, hard_delete: true)
        expect(stub).to have_been_requested
      end
    end

    describe '#read' do
      let!(:stub) do
        stub_request(
          :get,
          "#{stream_url(stream_name)}/0/forward/20?embed=body"
        ).with(headers: { 'Content-Type': 'application/vnd.eventstore.events+json' })
      end

      it 'sends a correct request' do
        api_client.read(stream_name, count: 20)
        expect(stub).to have_been_requested
      end
    end

    describe '#subscribe_to_stream' do
      let(:body) { { extraStatistics: true, startFrom: 0, maxRetryCount: 5, resolveLinkTos: true } }
      let!(:stub) do
        stub_request(
          :put,
          "#{store_base_url}/subscriptions/stream_name/subscription_name"
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
          "#{store_base_url}/subscriptions/stream_name/subscription_name/10?embed=body"
        ).with(
          headers: {
            'Content-Type': 'application/vnd.eventstore.competingatom+json',
            'Accept': 'application/vnd.eventstore.competingatom+json',
            'ES-LongPoll': '5'
          }
        )
      end

      it 'sends a correct request' do
        api_client.consume_feed(stream_name, 'subscription_name', count: 10, long_poll: 5)
        expect(stub).to have_been_requested
      end
    end

    describe '#link_to' do
      let(:event_1) do
        EventStoreClient::Event.new(
          id: SecureRandom.uuid,
          title: '3@Stream',
          type: 'SomethingHappened'
        )
      end

      let(:event_2) do
        EventStoreClient::Event.new(
          id: SecureRandom.uuid,
          title: '2@OtherStream',
          type: 'SomethingElseHappened'
        )
      end

      let(:body) do
        events.map do |event|
          {
            eventId: event.id,
            eventType: '$>',
            data: event.title
          }
        end
      end

      let!(:stub) do
        stub_request(:post, stream_url(stream_name)).
          with(body: body.to_json)
      end

      it 'sends a correct request' do
        api_client.link_to(stream_name, events)
        expect(stub).to have_been_requested
      end
    end

    private

    def store_base_url
      'https://www.example.com:8080'
    end

    def stream_url(name)
      "#{store_base_url}/streams/#{name}"
    end
  end
end
