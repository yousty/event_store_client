# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Connection do
  subject { instance }

  let(:instance) { described_class.allocate }
  let(:current_member) { EventStoreClient::GRPC::Cluster::Member.new(host: 'localhost', port: 301) }

  before do
    allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_return(current_member)
  end

  it { is_expected.to be_a(EventStoreClient::Configuration) }
  it { expect(subject.singleton_class).to be_a(EventStoreClient::Configuration) }
  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }
  it { is_expected.to have_option(:host).with_default_value(current_member.host) }
  it { is_expected.to have_option(:port).with_default_value(current_member.port) }
  it do
    is_expected.to(
      have_option(:username).with_default_value(EventStoreClient.config.eventstore_url.username)
    )
  end
  it do
    is_expected.to(
      have_option(:password).with_default_value(EventStoreClient.config.eventstore_url.password)
    )
  end
  it do
    is_expected.to(
      have_option(:timeout).with_default_value(EventStoreClient.config.eventstore_url.timeout)
    )
  end

  describe '.new' do
    subject { described_class.new }

    context 'when tls config option is set to true' do
      before do
        EventStoreClient.config.eventstore_url.tls = true
      end

      it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::SecureConnection) }
    end

    context 'when tls config option is set to false' do
      it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::InsecureConnection) }
    end
  end

  describe '.secure?' do
    subject { described_class.secure? }

    it { is_expected.to eq(false) }
  end

  describe '#call' do
    subject { instance.call(stub_class) }

    let(:stub_class) { double('some class') }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end
end
