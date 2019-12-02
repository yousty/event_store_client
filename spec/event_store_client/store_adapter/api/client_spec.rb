# frozen_string_literal: true

require_relative '../../event_store_helpers'
require 'webmock/rspec'

module EventStoreClient::StoreAdapter::Api
  RSpec.describe Client do
    let(:api_client) { described_class.new(host: 'https://www.example.com', port: 8080) }

    describe '#append_to_stream' do
      let!(:request) { stub_request(:post, 'https://www.example.com:8080/streams/stream_name') }

      it 'sends request' do
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

      it 'sends request' do
        api_client.delete_stream('stream_name', true)
        expect(request).to have_been_requested
      end
    end

    describe '#read' do
    end

    describe '#subscribe_to_stream' do
    end

    describe '#consume_feed' do
    end
  end
end
