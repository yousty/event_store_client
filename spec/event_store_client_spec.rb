# frozen_string_literal: true

RSpec.describe EventStoreClient do
  describe '.configure' do
    it 'yields config' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(EventStoreClient.config)
    end
  end

  describe '.config' do
    subject { described_class.config }

    it { is_expected.to be_a(described_class::Config) }
    it 'memorizes the config object' do
      expect(subject.__id__).to eq(described_class.config.__id__)
    end
  end

  describe '.client' do
    subject { described_class.client }

    it { is_expected.to be_a(described_class::GRPC::Client) }
  end
end
