# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::LinkToMultiple do
  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }

  describe '#call' do
    subject { instance.call(stream_name, events, options: options) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:other_stream_name) { "other-stream$#{SecureRandom.uuid}" }
    let(:options) { {} }
    let(:events) do
      2.times.map do
        event = EventStoreClient::DeserializedEvent.new(type: 'some-event', data: { foo: :bar })
        EventStoreClient.client.append_to_stream(other_stream_name, event)
        EventStoreClient.client.read(other_stream_name).success.last
      end
    end

    it 'links event' do
      expect { subject }.to change { EventStoreClient.client.read(stream_name).success&.size }.to(2)
    end

    describe 'linked events' do
      subject do
        super()
        EventStoreClient.client.read(stream_name, options: { resolve_link_tos: true }).success
      end

      it 'returns linked events' do
        is_expected.to eq(events)
      end
    end
  end
end
