# frozen_string_literal: true

require_relative '../../event_store_helpers'

module EventStoreClient::StoreAdapter::Api
  RSpec.describe Client do
    let(:api_client) { described_class.new(host: 'https://www.example.com', port: 8080) }

    describe '#append_to_stream' do
      before do
        # allow(Faraday).to receive(:post).with('smile', 'nosmile').and_return(body: 'example')
        # How to stub Faraday?
      end

      it 'sends request' do
        events = [
          EventStoreClient::Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json),
          EventStoreClient::Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
        ]
        # api_client.append_to_stream('stream', events)
      end
    end

    describe '#delete_stream' do
    end

    describe '#read' do
    end

    describe '#subscribe_to_stream' do
    end

    describe '#consume_feed' do
    end
  end
end
