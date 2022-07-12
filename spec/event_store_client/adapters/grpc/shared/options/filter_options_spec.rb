# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Shared::Options::FilterOptions do
  subject { instance }

  let(:instance) { described_class.new(options) }
  let(:options) { {} }

  describe '#request_options' do
    subject { instance.request_options }

    it { is_expected.to be_a(Hash) }

    shared_examples 'window options' do
      context 'when :checkpointIntervalMultiplier option is not provided' do
        it 'includes its default value' do
          expect(subject[:filter]).to include(checkpointIntervalMultiplier: 1)
        end
      end

      context 'when :max option is not provided' do
        it 'includes its default value' do
          expect(subject[:filter]).to include(max: 100)
        end
      end

      context 'when :count option is not provided' do
        it 'does not include it' do
          expect(subject[:filter]).not_to include(:count)
        end
      end

      context 'when :checkpointIntervalMultiplier option is provided' do
        let(:options) { super().merge(checkpointIntervalMultiplier: 2)  }

        it 'includes its provided value' do
          expect(subject[:filter]).to include(checkpointIntervalMultiplier: 2)
        end
      end

      context 'when :max option is provided' do
        let(:options) { super().merge(max: 22) }

        it 'includes its provided value' do
          expect(subject[:filter]).to include(max: 22)
        end
      end

      context 'when :count option is provided' do
        let(:options) { super().merge(count: true) }

        it 'includes its provided value' do
          expect(subject[:filter]).to include(count: EventStore::Client::Empty.new)
        end
      end
    end

    context 'when options is not provided' do
      let(:options) { nil }

      it { is_expected.to eq(no_filter: EventStore::Client::Empty.new) }
    end

    context 'when :stream_identifier option is provided' do
      let(:options) { { stream_identifier: { regex: '/.*/' } } }

      context 'when :stream_identifier option contains :regex' do
        it 'recognizes it' do
          expect(subject[:filter]).to include(stream_identifier: { regex: '/.*/' })
        end
        it_behaves_like 'window options'
      end

      context 'when :stream_identifier option contains :prefix' do
        let(:options) { { stream_identifier: { prefix: ['asd'] } } }

        it 'recognizes it' do
          expect(subject[:filter]).to include(stream_identifier: { prefix: ['asd'] })
        end
        it_behaves_like 'window options'
      end

      context 'when :stream_identifier option contains incorrect value' do
        let(:options) { { stream_identifier: { prefix: 'asd' } } }

        it 'does not recognize it' do
          is_expected.to eq(no_filter: EventStore::Client::Empty.new)
        end
      end
    end

    context 'when :event_type option is provided' do
      let(:options) { { event_type: { regex: '/.*/' } } }

      context 'when :event_type option contains :regex' do
        it 'recognizes it' do
          expect(subject[:filter]).to include(event_type: { regex: '/.*/' })
        end
        it_behaves_like 'window options'
      end

      context 'when :event_type option contains :prefix' do
        let(:options) { { event_type: { prefix: ['asd'] } } }

        it 'recognizes it' do
          expect(subject[:filter]).to include(event_type: { prefix: ['asd'] })
        end
        it_behaves_like 'window options'
      end

      context 'when :event_type option contains incorrect value' do
        let(:options) { { event_type: { prefix: 'asd' } } }

        it 'does not recognize it' do
          is_expected.to eq(no_filter: EventStore::Client::Empty.new)
        end
      end
    end
  end
end
