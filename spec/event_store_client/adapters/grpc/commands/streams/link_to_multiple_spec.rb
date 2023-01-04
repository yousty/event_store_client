# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::LinkToMultiple do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }

  describe '#call' do
    subject { instance.call(stream_name, events, options: options) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:other_stream_name) { "other-stream$#{SecureRandom.uuid}" }
    let(:options) { {} }
    let(:events) do
      2.times.map do
        event = EventStoreClient::DeserializedEvent.new(type: 'some-event', data: { foo: :bar })
        append_and_reload(other_stream_name, event)
      end
    end

    it 'links event' do
      expect { subject }.to change { safe_read(stream_name)&.size }.to(2)
    end

    describe 'linked events' do
      subject do
        super()
        EventStoreClient.client.read(stream_name, options: { resolve_link_tos: true })
      end

      it 'returns linked events' do
        is_expected.to eq(events)
      end
    end
  end
end
