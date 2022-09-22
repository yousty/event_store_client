# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Options::Streams::ReadOptions do
  subject { instance }

  let(:instance) { described_class.new(stream_name, options) }
  let(:stream_name) { 'some-stream' }
  let(:options) { {} }

  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe '#request_options' do
    subject { instance.request_options }

    it { is_expected.to be_a(Hash) }
    it 'has default value' do
      aggregate_failures 'default values' do
        expect(subject[:stream]).to(
          eq(start: EventStore::Client::Empty.new, stream_identifier: { stream_name: stream_name })
        )
        expect(subject).to include(read_direction: nil)
        expect(subject[:count]).to eq(EventStoreClient.config.per_page)
        expect(subject).to include(resolve_links: nil)
        expect(subject[:no_filter]).to eq(EventStore::Client::Empty.new)
        expect(subject[:uuid_option]).to eq(string: EventStore::Client::Empty.new)
      end
    end

    context 'when :direction option is provided' do
      let(:options) { { direction: 'Backwards' } }

      it 'recognizes it' do
        expect(subject[:read_direction]).to eq('Backwards')
      end
    end

    context 'when :max_count option is provided' do
      let(:options) { { max_count: 100_500 } }

      it 'recognizes it' do
        expect(subject[:count]).to eq(100_500)
      end
    end

    context 'when :resolve_link_tos option is provided' do
      let(:options) { { resolve_link_tos: true } }

      it 'recognizes it' do
        expect(subject[:resolve_links]).to eq(true)
      end
    end

    context 'when :from_revision option is provided' do
      let(:options) { { from_revision: :end } }

      it 'recognizes it' do
        expect(subject[:stream][:end]).to eq(EventStore::Client::Empty.new)
      end
    end

    context 'when :from_position option is provided' do
      let(:options) { { from_position: :end } }
      let(:stream_name) { '$all' }

      it 'recognizes it' do
        expect(subject[:all][:end]).to eq(EventStore::Client::Empty.new)
      end
    end

    context 'when :filter option is provided' do
      let(:options) { { filter: { stream_identifier: { prefix: ['lol'] } } } }

      it 'recognizes it' do
        expect(subject[:filter]).to include(options[:filter])
      end
    end
  end
end
