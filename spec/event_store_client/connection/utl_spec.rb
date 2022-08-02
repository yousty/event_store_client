# frozen_string_literal: true

RSpec.describe EventStoreClient::Connection::Url do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }
  it { is_expected.to have_option(:dns_discover).with_default_value(false) }
  it { is_expected.to have_option(:username).with_default_value('admin') }
  it { is_expected.to have_option(:password).with_default_value('changeit') }
  it { is_expected.to have_option(:throw_on_append_failure).with_default_value(true) }
  it { is_expected.to have_option(:tls).with_default_value(true) }
  it { is_expected.to have_option(:tls_verify_cert).with_default_value(false) }
  it { is_expected.to have_option(:tls_ca_file) }
  it { is_expected.to have_option(:ca_lookup_interval).with_default_value(100) }
  it { is_expected.to have_option(:ca_lookup_attempts).with_default_value(3) }
  it { is_expected.to have_option(:gossip_timeout).with_default_value(200) }
  it { is_expected.to have_option(:max_discover_attempts).with_default_value(10) }
  it { is_expected.to have_option(:discover_interval).with_default_value(100) }
  it { is_expected.to have_option(:timeout) }
  it do
    is_expected.to(
      have_option(:node_preference).with_default_value(described_class::NODE_PREFERENCES.first)
    )
  end
  it { is_expected.to have_option(:connection_name).with_default_value('default') }
  it { is_expected.to have_option(:nodes).with_default_value(Set.new) }
  it { is_expected.to have_option(:grpc_retry_attempts).with_default_value(3) }
  it { is_expected.to have_option(:grpc_retry_interval).with_default_value(100) }

  describe 'constants' do
    describe 'NODE_PREFERENCES' do
      subject { described_class::NODE_PREFERENCES }

      it { is_expected.to eq(%i(Leader Follower ReadOnlyReplica))  }
      it { is_expected.to be_frozen }
    end

    describe 'Node' do
      subject { described_class::Node }

      it { is_expected.to be < Struct }

      describe 'instance' do
        subject { described_class::Node.new(host, port) }

        let(:host) { 'localhost' }
        let(:port) { 2111 }

        it 'has proper attributes' do
          aggregate_failures do
            expect(subject.host).to eq(host)
            expect(subject.port).to eq(port)
          end
        end
      end
    end
  end
end
