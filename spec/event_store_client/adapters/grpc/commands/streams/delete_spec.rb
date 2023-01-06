# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Delete do
  subject { instance }

  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.new(config: config) }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it 'uses correct params class' do
    expect(instance.request).to eq(EventStore::Client::Streams::DeleteReq)
  end
  it 'uses correct service' do
    expect(instance.service).to be_a(EventStore::Client::Streams::Streams::Stub)
  end

  describe '#call' do
    subject { instance.call(stream_name, options: {}) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }

    describe 'deleting existing stream' do
      let(:event) do
        EventStoreClient::DeserializedEvent.new(
          id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
        )
      end

      before do
        EventStoreClient.client.append_to_stream(stream_name, event)
      end

      it 'deletes stream' do
        expect { subject }.to change {
          EventStoreClient.client.read(stream_name) rescue nil
        }.from(kind_of(Array)).to(nil)
      end
      it { is_expected.to be_a(EventStore::Client::Streams::DeleteResp) }
    end

    describe 'deleting non-existing stream' do
      it 'raises error' do
        expect { subject }.to(
          raise_error(EventStoreClient::StreamDeletionError, a_string_including(stream_name))
        )
      end
    end
  end
end
