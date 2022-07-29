# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Cluster::QuerylessDiscover do
  subject { instance }

  let(:instance) { described_class.new }

  describe 'constants' do
    describe 'NoHostError' do
      subject { described_class::NoHostError }

      it { is_expected.to be < StandardError }
    end
  end

  describe '#call' do
    subject { instance.call(nodes) }

    let(:nodes) { [] }

    context 'when nodes are absent' do
      it 'raises error' do
        expect { subject }.to raise_error(described_class::NoHostError, 'No host is setup')
      end
    end

    context 'when nodes are present' do
      let(:nodes) { [EventStoreClient::Connection::Url::Node.new('localhost', 3000)] }

      it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member) }
      it 'has proper attributes' do
        aggregate_failures do
          expect(subject.host).to eq(nodes.first.host)
          expect(subject.port).to eq(nodes.first.port)
        end
      end
    end
  end
end
