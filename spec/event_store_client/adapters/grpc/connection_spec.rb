# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Connection do
  subject { instance }

  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.allocate }
  let(:current_member) { EventStoreClient::GRPC::Cluster::Member.new(host: 'localhost', port: 301) }

  before do
    allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_return(current_member)
  end

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }

  describe 'options' do
    before do
      allow(instance).to receive(:config).and_return(config)
    end

    it { is_expected.to have_option(:host) }
    it { is_expected.to have_option(:port) }
    it { is_expected.to have_option(:username) }
    it { is_expected.to have_option(:password) }
    it { is_expected.to have_option(:timeout) }

    describe 'default :host value' do
      subject { instance.host }

      it { is_expected.to eq(current_member.host) }
    end

    describe 'default :port value' do
      subject { instance.port }

      it { is_expected.to eq(current_member.port) }
    end

    describe 'default :username value' do
      subject { instance.username }

      it { is_expected.to eq(config.eventstore_url.username) }
    end

    describe 'default :password value' do
      subject { instance.password }

      it { is_expected.to eq(config.eventstore_url.password) }
    end

    describe 'default :timeout value' do
      subject { instance.timeout }

      it { is_expected.to eq(config.eventstore_url.timeout) }
    end
  end

  describe '.new' do
    subject { described_class.new(config: config) }

    context 'when tls config option is set to true' do
      before do
        config.eventstore_url.tls = true
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
