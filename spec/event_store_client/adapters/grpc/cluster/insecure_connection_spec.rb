# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Cluster::InsecureConnection do
  subject { instance }

  let(:instance) { described_class.new }
  let(:member) { EventStoreClient::GRPC::Cluster::Member.new(host: 'host.local', port: 1234) }

  before do
    allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_return(member)
  end

  it { is_expected.to be_a(EventStoreClient::GRPC::Connection) }

  describe '.secure?' do
    subject { described_class.secure? }

    it { is_expected.to eq(false) }
  end

  describe '#call' do
    subject { instance.call(stub_class) }

    let(:stub_class) { EventStore::Client::Gossip::Gossip::Stub }

    before do
      EventStoreClient.config.eventstore_url.timeout = 1001
    end

    it { is_expected.to be_a(stub_class) }
    it 'has correct host' do
      host = subject.instance_variable_get(:@host)
      expect(host).to eq("#{member.host}:#{member.port}")
    end
    it 'has correct timeout' do
      timeout = subject.instance_variable_get(:@timeout)
      expect(timeout).to eq(EventStoreClient.config.eventstore_url.timeout / 1000.0)
    end

    describe 'real request' do
      subject { super().read(EventStore::Client::Empty.new) }

      before do
        allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_call_original
      end

      it 'does not raise any errors' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
