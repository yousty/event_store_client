# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Options::Streams::RevisionOption do
  subject { instance }

  let(:instance) { described_class.new(value) }
  let(:value) { 2 }

  describe '#request_options' do
    subject { instance.request_options }

    context 'when value is Integer' do
      it { is_expected.to eq(revision: value) }
    end

    context 'when value is a string' do
      let(:value) { 'some-val' }

      context 'when case is unhandled' do
        it { is_expected.to eq(any: EventStore::Client::Empty.new) }
      end

      context 'when value is "any"' do
        let(:value) { 'any' }

        it { is_expected.to eq(any: EventStore::Client::Empty.new) }
      end

      context 'when value is "no_stream"' do
        let(:value) { 'no_stream' }

        it { is_expected.to eq(no_stream: EventStore::Client::Empty.new) }
      end

      context 'when value is "stream_exists"' do
        let(:value) { 'stream_exists' }

        it { is_expected.to eq(stream_exists: EventStore::Client::Empty.new) }
      end
    end

    context 'when value is something else' do
      let(:value) { Object.new }

      it { is_expected.to eq(any: EventStore::Client::Empty.new) }
    end
  end

  describe '#number?' do
    subject { instance.number? }

    context 'when value is Integer' do
      it { is_expected.to be_truthy }
    end

    context 'when value is something else' do
      let(:value) { 'lol' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#increment!' do
    subject { instance.increment! }

    it 'increments :revision by 1' do
      expect { subject }.to change { instance.request_options[:revision] }.by(1)
    end
  end
end
