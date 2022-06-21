# frozen_string_literal: true

require 'event_store_client/adapters/http'
require 'support/dummy_handler'

module EventStoreClient::HTTP
  RSpec.describe Client do
    let(:api_client) { described_class.new }

    let(:stream_name) { :stream_name }
    let(:events) { [event_1, event_2] }

    describe '#append_to_stream' do
      let(:event_1) do
        EventStoreClient::SomethingHappened.new(id: SecureRandom.uuid, data: { foo: 'bar' })
      end
      let(:event_2) do
        EventStoreClient::SomethingHappened.new(id: SecureRandom.uuid, data: { foo: 'bar' })
      end
      let(:body) do
        events.map do |event|
          e = EventStoreClient::Mapper::Default.new.serialize(event)
          {
            eventId: e.id,
            eventType: e.type,
            data: e.data,
            metadata: e.metadata
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
        api_client.append_to_stream(stream_name, events, options: { expected_version: 0 })
        expect(stub).to have_been_requested
      end

      it 'raises exception when passed a wrong expected version' do
        res = api_client.append_to_stream(stream_name, events, options: { expected_version: 10 })
        expect(res).to be_failure
        expect(res.failure).to eq('current version: 0 | expected: 10')
      end
    end

    describe '#delete_stream' do
      let!(:stub) do
        stub_request(:delete, stream_url(stream_name))
      end

      it 'sends a correct request' do
        api_client.delete_stream(stream_name)
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
        api_client.read(stream_name, options: { count: 20 })
        expect(stub).to have_been_requested
      end
    end

    describe '#subscribe_to_stream' do
      let(:body) do
        {
          extraStatistics: true,
          startFrom: 0,
          maxRetryCount: 5,
          maxCheckPointCount: 0,
          minCheckPointCount: 0,
          resolveLinkTos: true
        }
      end
      let!(:stub) do
        stub_request(:post, "#{store_base_url}/projections/continuous?emit=true&enabled=yes&name=default-DummyHandler&trackemittedstreams=true&type=js"). # rubocop:disable Metrics/LineLength
          with(
            body: "fromStreams([])\n.when({\n  $any: function(s,e) {\n    linkTo(\"default-DummyHandler\", e)\n  }\n})\n" # rubocop:disable Metrics/LineLength
          )
        stub_request(
          :put,
          "#{store_base_url}/subscriptions/default-DummyHandler/default-DummyHandler"
        ).with(
          headers: { 'Content-Type': 'application/json' },
          body: body.to_json
        )
      end

      it 'sends a correct request' do
        subscription = EventStoreClient::Subscription.new(
          DummyHandler, event_types: [], service: 'default'
        )
        api_client.subscribe_to_stream(
          subscription, options: { stats: true, start_from: 0, retries: 5 }
        )
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
      ENV['EVENTSTORE_URL']
    end

    def stream_url(name)
      "#{store_base_url}/streams/#{name}"
    end
  end
end
