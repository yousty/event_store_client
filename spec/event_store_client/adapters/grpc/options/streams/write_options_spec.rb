# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Options::Streams::WriteOptions do
  subject { instance }

  let(:instance) { described_class.new(stream_name, options) }
  let(:stream_name) { 'some=stream' }
  let(:options) { {} }

  describe '#request_options' do
    subject { instance.request_options }

    context 'when options is empty' do
      it 'returns default value' do
        is_expected.to(
          eq(stream_identifier: { stream_name: stream_name }, any: EventStore::Client::Empty.new)
        )
      end
    end

    context 'when :expected_revision option is :any' do
      let(:options) { { expected_revision: :any } }

      it 'recognizes it' do
        is_expected.to(
          eq(stream_identifier: { stream_name: stream_name }, any: EventStore::Client::Empty.new)
        )
      end
    end

    context 'when :expected_revision option is :no_stream' do
      let(:options) { { expected_revision: :no_stream } }

      it 'recognizes it' do
        is_expected.to(
          eq(
            stream_identifier: { stream_name: stream_name },
            no_stream: EventStore::Client::Empty.new
          )
        )
      end
    end

    context 'when :expected_revision option is :stream_exists' do
      let(:options) { { expected_revision: :stream_exists } }

      it 'recognizes it' do
        is_expected.to(
          eq(
            stream_identifier: { stream_name: stream_name },
            stream_exists: EventStore::Client::Empty.new
          )
        )
      end
    end

    context 'when :expected_revision option is Integer' do
      let(:options) { { expected_revision: 123 } }

      it 'recognizes it' do
        is_expected.to(
          eq(stream_identifier: { stream_name: stream_name }, revision: 123)
        )
      end
    end
  end
end
