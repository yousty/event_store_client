# frozen_string_literal: true

RSpec.describe EventStoreClient::StreamNotFoundError do
  subject { instance }

  let(:instance) { described_class.new(stream_name) }
  let(:stream_name) { 'some-stream' }

  it { is_expected.to be_a(EventStoreClient::Error) }

  describe '#message' do
    subject { instance.message }

    it { is_expected.to eq("Stream #{stream_name.inspect} does not exist.") }
  end

  describe '#stream_name' do
    subject { instance.stream_name }

    it { is_expected.to eq(stream_name) }
  end
end
