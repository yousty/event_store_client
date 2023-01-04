# frozen_string_literal: true

RSpec.describe 'Multiple configuration handling' do
  let!(:config1) do
    EventStoreClient.configure do |config|
      config.eventstore_url = url1
    end
  end
  let!(:config2) do
    EventStoreClient.configure(name: :another_config) do |config|
      config.eventstore_url = url2
    end
  end
  let(:url1) { 'esdb://admin:changeit@localhost:2111,localhost:2112,localhost:2113' }
  let(:url2) { 'esdb://admin:changeit@localhost:2115/?tls=false' }
  let(:client1) { EventStoreClient.client }
  let(:client2) { EventStoreClient.client(config_name: :another_config) }

  describe 'reading/writing events' do
    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:event) { EventStoreClient::DeserializedEvent.new(id: SecureRandom.uuid) }
    let(:read_opts) { { options: { filter: { stream_identifier: { prefix: [stream_name] } } } } }

    before do
      client2.append_to_stream(stream_name, event)
    end

    it 'reads event from correct ES server' do
      aggregate_failures do
        expect(client2.read('$all', **read_opts).map(&:id)).to eq([event.id])
        expect(client1.read('$all', **read_opts)).to be_empty
      end
    end
  end
end
