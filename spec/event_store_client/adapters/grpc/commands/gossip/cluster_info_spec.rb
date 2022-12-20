# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Gossip::ClusterInfo do
  subject { instance }

  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.new(config: config) }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it 'uses correct params class' do
    expect(subject.request).to eq(EventStore::Client::Empty)
  end
  it 'uses correct service' do
    expect(subject.service).to be_a(EventStore::Client::Gossip::Gossip::Stub)
  end

  describe '#call' do
    subject { instance.call }

    it { is_expected.to be_a(Dry::Monads::Success) }
    it 'returns cluster info' do
      expect(subject.success).to be_a(EventStore::Client::Gossip::ClusterInfo)
    end
  end
end
