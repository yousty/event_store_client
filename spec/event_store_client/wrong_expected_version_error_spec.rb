# frozen_string_literal: true

RSpec.describe EventStoreClient::WrongExpectedVersionError do
  subject { instance }

  let(:instance) { described_class.new(wrong_expected_version, caused_by: caused_by) }
  let(:wrong_expected_version) { EventStore::Client::Streams::AppendResp::WrongExpectedVersion.new }
  let(:caused_by) { EventStoreClient::DeserializedEvent.new(id: '123') }

  it { is_expected.to be_a(EventStoreClient::Error) }

  describe '#wrong_expected_version' do
    subject { instance.wrong_expected_version }

    it { is_expected.to eq(wrong_expected_version) }
  end

  describe '#caused_by' do
    subject { instance.caused_by }

    it { is_expected.to eq(caused_by) }
  end

  describe '#message' do
    subject { instance.message }

    context 'when "expected stream to exist" error is returned' do
      before do
        wrong_expected_version.expected_stream_exists = EventStore::Client::Empty.new
      end

      it { is_expected.to eq("Expected stream to exist, but it doesn't.") }
    end

    context 'when "expected no stream to exist" error is returned' do
      before do
        wrong_expected_version.expected_no_stream = EventStore::Client::Empty.new
      end

      it { is_expected.to eq("Expected stream to be absent, but it actually exists.") }
    end

    context 'when stream revision is set, but stream does not exist' do
      before do
        wrong_expected_version.expected_revision = 1
        wrong_expected_version.current_no_stream = EventStore::Client::Empty.new
      end

      it { is_expected.to eq("Stream revision 1 is expected, but stream does not exist.") }
    end

    context 'when stream revision does not match the expected revision' do
      before do
        wrong_expected_version.current_revision = 1
        wrong_expected_version.expected_revision = 2
      end

      it { is_expected.to eq("Stream revision 2 is expected, but actual stream revision is 1.") }
    end

    context 'unhandled case' do
      it { is_expected.to eq(described_class.to_s) }
    end
  end
end
