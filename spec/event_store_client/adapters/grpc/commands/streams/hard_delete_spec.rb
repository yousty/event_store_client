# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::HardDelete do
  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe '#call' do
    subject { instance.call(stream_name) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }

    describe 'deleting existing stream' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(
          id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
        )
      end

      before do
        EventStoreClient.client.append_to_stream(stream_name, [event])
      end

      it 'deletes stream' do
        expect { subject }.to change {
          EventStoreClient.client.read(stream_name)
        }.from(be_success).to(be_failure)
      end
      it 'returns correct failure message' do
        subject
        expect(EventStoreClient.client.read(stream_name).failure).to eq(:stream_not_found)
      end
    end

    describe 'deleting non-existing stream' do
      it 'returns correct failure message' do
        subject
        expect(EventStoreClient.client.read(stream_name).failure).to eq(:stream_not_found)
      end
    end
  end
end
