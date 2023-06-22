# frozen_string_literal: true

RSpec.describe EventStoreClient::EventClassResolver do
  let(:instance) { described_class.new(config) }
  let(:config) { EventStoreClient.config }

  describe '#resolve' do
    subject { instance.resolve(event_type) }

    let(:event_type) { 'SomeEvent' }

    context 'when event type matches existing class' do
      let(:event_class) { Class.new(EventStoreClient::DeserializedEvent) }

      before do
        stub_const(event_type, event_class)
      end

      it { is_expected.to eq(SomeEvent) }
    end

    context 'when event type is nil' do
      let(:event_type) { nil }

      it { is_expected.to eq(EventStoreClient::DeserializedEvent) }
    end

    context 'when event type is something else' do
      let(:event_type) { Object.new }

      it { is_expected.to eq(EventStoreClient::DeserializedEvent) }
    end

    context 'when custom default event class is provided' do
      before do
        stub_const('SomeClass', Class.new)
        config.default_event_class = SomeClass
      end

      it { is_expected.to eq(SomeClass) }
    end

    context 'when custom event class resolver is defined' do
      before do
        stub_const('SomeClass', Class.new(EventStoreClient::DeserializedEvent))
        config.event_class_resolver = ->(event_type) { SomeClass }
      end

      it 'respects it' do
        is_expected.to eq(SomeClass)
      end
    end

    context 'when custom event class resolver returns nil' do
      before do
        config.event_class_resolver = ->(event_type) { }
      end

      it { is_expected.to eq(EventStoreClient::DeserializedEvent) }
    end
  end
end
