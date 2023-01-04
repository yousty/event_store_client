# frozen_string_literal: true

RSpec.describe EventStoreClient::StreamDeletionError do
  subject { instance }

  let(:instance) { described_class.new(stream_name, details: details) }
  let(:stream_name) { 'some-stream' }
  let(:details) { 'some details goes here' }

  it { is_expected.to be_a(EventStoreClient::Error) }

  describe '#message' do
    subject { instance.message }

    it { is_expected.to include("Could not delete #{stream_name.inspect} stream.") }
  end

  describe '#stream_name' do
    subject { instance.stream_name }

    it { is_expected.to eq(stream_name) }
  end

  describe '#details' do
    subject { instance.details }

    it { is_expected.to eq(details) }
  end
end
