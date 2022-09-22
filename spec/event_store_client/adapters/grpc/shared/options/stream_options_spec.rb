# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Shared::Options::StreamOptions do
  subject { instance }

  let(:instance) { described_class.new(stream_name, options) }
  let(:stream_name) { 'some-stream' }
  let(:options) { {} }

  describe '#request_options' do
    subject { instance.request_options }

    context 'when stream name is a regular name' do
      context 'when options are not provided' do
        it 'returns default value' do
          is_expected.to(
            eq(
              stream: {
                stream_identifier: { stream_name: stream_name },
                start: EventStore::Client::Empty.new
              }
            )
          )
        end
      end

      context 'when :from_revision option is provided' do
        let(:options) { { from_revision: :start } }

        context 'when :from_revision is :start' do
          it 'recognizes it' do
            expect(subject[:stream]).to include(start: EventStore::Client::Empty.new)
          end
        end

        context 'when :from_revision is :end' do
          let(:options) { { from_revision: :end } }

          it 'recognizes it' do
            expect(subject[:stream]).to include(end: EventStore::Client::Empty.new)
          end
        end

        context 'when :from_revision is Integer' do
          let(:options) { { from_revision: 123 } }

          it 'recognizes it' do
            expect(subject[:stream]).to include(revision: 123)
          end
        end
      end

      context 'when :from_position option is provided' do
        let(:options) { { from_position: 123 } }

        it 'does not recognize it' do
          expect(subject[:stream]).not_to include(:position)
        end
      end
    end

    context 'when stream name is $all' do
      let(:stream_name) { '$all' }

      context 'when options are not provided' do
        it 'returns default value' do
          is_expected.to eq(all: {start: EventStore::Client::Empty.new})
        end
      end

      context 'when :from_position option is provided' do
        let(:options) { { from_position: :start } }

        context 'when :from_position is :start' do
          it 'recognizes it' do
            expect(subject[:all]).to eq(start: EventStore::Client::Empty.new)
          end
        end

        context 'when :from_position is :end' do
          let(:options) { { from_position: :end } }

          it 'recognizes it' do
            expect(subject[:all]).to eq(end: EventStore::Client::Empty.new)
          end
        end

        context 'when :from_position is Hash' do
          let(:options) { { from_position: { commit_position: 123, prepare_position: 123 } } }

          it 'recognizes it' do
            expect(subject[:all]).to eq(position: { commit_position: 123, prepare_position: 123 })
          end
        end
      end

      context 'when :from_revision option is provided' do
        let(:options) { { from_revision: 123 } }

        it 'does not recognize it' do
          expect(subject[:all]).not_to include(:revision)
        end
      end
    end
  end
end
