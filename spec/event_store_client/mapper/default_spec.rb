# frozen_string_literal: true

RSpec.describe EventStoreClient::Mapper::Default do
  let(:data) do
    {
      'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
      'email' => 'darth@vader.sv'
    }
  end
  let(:default_event) do
    Class.new(EventStoreClient::DeserializedEvent) do
      def self.to_s
        'DefaultEvent'
      end

      def schema
        Dry::Schema.Params do
          required(:user_id).value(:string)
          required(:email).value(:string)
        end
      end
    end
  end
  let(:serialized_default_event) do
    Class.new(EventStoreClient::Event) do
      def self.to_s
        'SerializedDefaultEvent'
      end

      def metadata
        '{"created_at":"2019-12-05 19:37:38 +0100"}'
      end

      def data
        '{"user_id":"dab48d26-e4f8-41fc-a9a8-59657e590716","email":"darth@vader.sv"}'
      end
    end
  end

  before do
    stub_const(default_event.to_s, default_event)
    stub_const(serialized_default_event.to_s, default_event)
  end

  describe '#serialize' do
    subject { described_class.new.serialize(user_registered) }

    let(:user_registered) { default_event.new(data: data) }

    it 'returns serialized event' do
      expect(subject).to be_kind_of(EventStoreClient::Event)
      expect(subject.data).to eq(JSON.generate(data))
      expect(subject.metadata).to include('created_at')
      expect(subject.type).to eq('DefaultEvent')
    end
  end

  describe '#deserialize' do
    context 'when the event type const exists' do
      subject { described_class.new.deserialize(event) }

      let(:event) { serialized_default_event.new(type: 'DefaultEvent') }

      before do
        allow(default_event).to receive(:new).and_call_original
      end

      it 'returns instance of DefaultEvent' do
        expect(subject).to be_kind_of(default_event)
        expect(subject.data).to eq(data)
        expect(subject.metadata['created_at']).not_to be_nil
        expect(subject.type).to eq('DefaultEvent')
      end

      it 'skips validation' do
        subject
        expect(default_event).to have_received(:new).with(hash_including(skip_validation: true))
      end
    end

    context 'when the event type const does not exist' do
      let(:event) { serialized_default_event.new(type: 'SomethingHappened') }

      subject { described_class.new.deserialize(event) }

      it 'returns instance of DeserializedEvent' do
        expect(subject).to be_kind_of(EventStoreClient::DeserializedEvent)
        expect(subject.data).to eq(data)
        expect(subject.metadata['created_at']).not_to be_nil
        expect(subject.type).to eq('SomethingHappened')
      end
    end
  end
end
