# frozen_string_literal: true

require_relative '../../event_store_helpers'
require 'webmock/rspec'

module EventStoreClient::StoreAdapter::Api
  RSpec.describe Client do
    let(:api_client) { described_class.new(host: 'https://www.example.com', port: 8080) }

    describe '#append_to_stream' do
      let!(:request) { stub_request(:post, 'https://www.example.com:8080/streams/stream_name') }

      it 'sends a correct request' do
        events = [
          EventStoreClient::Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json),
          EventStoreClient::Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
        ]
        api_client.append_to_stream('stream_name', events)
        expect(request).to have_been_requested
      end
    end

    describe '#delete_stream' do
      let!(:request) { stub_request(:delete, 'https://www.example.com:8080/streams/stream_name') }

      it 'sends a correct request' do
        api_client.delete_stream('stream_name', true)
        expect(request).to have_been_requested
      end
    end

    describe '#read' do
      let!(:request) do
        stub_request(
          :get,
          'https://www.example.com:8080/streams/stream_name/0/forward/20?embed=body'
        )
      end

      it 'sends a correct request' do
        api_client.read('stream_name', count: 20)
        expect(request).to have_been_requested
      end
    end

    describe '#subscribe_to_stream' do
      let!(:request) do
        stub_request(
          :put,
          'https://www.example.com:8080/subscriptions/stream_name/subscription_name'
        )
      end

      it 'sends a correct request' do
        api_client.subscribe_to_stream('stream_name', 'subscription_name')
        expect(request).to have_been_requested
      end
    end

    describe '#consume_feed' do
      let!(:request) do
        stub_request(
          :get,
          'https://www.example.com:8080/subscriptions/stream_name/subscription_name/10?embed=body'
        )
      end

      it 'sends a correct request' do
        api_client.consume_feed('stream_name', 'subscription_name', count: 10)
        expect(request).to have_been_requested
      end
    end
  end
end
