# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Cluster::SecureConnection do
  subject { instance }

  let(:options)  { { config: EventStoreClient.config } }
  let(:instance) { described_class.new(**options) }
  let(:member) { EventStoreClient::GRPC::Cluster::Member.new(host: 'host.local', port: 1234) }

  before do
    allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_return(member)
  end

  it { is_expected.to be_a(EventStoreClient::GRPC::Connection) }

  describe 'constants' do
    describe 'CertificateLookupError' do
      subject { described_class::CertificateLookupError }

      it { is_expected.to be < StandardError }
    end
  end

  describe '.secure?' do
    subject { described_class.secure? }

    it { is_expected.to be_truthy }
  end

  describe '#call' do
    subject { instance.call(stub_class) }

    let(:stub_class) { EventStore::Client::Streams::Streams::Stub }

    before do
      EventStoreClient.config.eventstore_url.timeout = 1001
    end

    describe 'with stubbed certificate' do
      before do
        allow(instance).to receive(:cert).and_return(nil)
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
    end

    describe 'real request' do
      subject { super().read(request_options, metadata: metadata).first }

      let(:config) { EventStoreClient.config }
      let(:request_options) do
        options = EventStoreClient::GRPC::Options::Streams::ReadOptions.new(
          '$all', {}, config: config
        ).request_options
        options = EventStore::Client::Streams::ReadReq::Options.new(options)
        EventStore::Client::Streams::ReadReq.new(
          options: options
        )
      end
      let(:metadata) do
        creds =
          Base64.encode64("#{instance.username}:#{instance.password}").delete("\n")
        { 'authorization' => "Basic #{creds}" }
      end

      before do
        allow(EventStoreClient::GRPC::Discover).to receive(:current_member).and_call_original
        EventStoreClient.config.eventstore_url =
          'esdb://localhost:2111,localhost:2112,localhost:2113/?tls=true'
      end

      it 'does not raise any errors' do
        expect { subject }.not_to raise_error
      end

      context 'when credentials are invalid' do
        before do
          instance.username = 'anon'
        end

        it 'raises auth error' do
          expect { subject }.to raise_error(GRPC::Unauthenticated)
        end
      end

      context 'when certificate is provided' do
        before do
          EventStoreClient.config.eventstore_url.tls_ca_file =
            File.join(TestHelper.root_path, 'certs/ca/ca.crt')
          # stub this method to prevent false-positive result in case if handling of custom CA file
          # is not properly handled
          allow(instance).to receive(:cert)
        end

        it 'does not raise any errors' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
