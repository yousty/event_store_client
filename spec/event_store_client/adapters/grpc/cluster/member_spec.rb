# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Cluster::Member do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }
  it { is_expected.to have_option(:host) }
  it { is_expected.to have_option(:port) }
  it { is_expected.to have_option(:active) }
  it { is_expected.to have_option(:instance_id) }
  it { is_expected.to have_option(:state) }
  it { is_expected.to have_option(:failed_endpoint).with_default_value(false) }
end
