# frozen_string_literal: true

module EventStoreClient
  RSpec.describe Mapper::Default do
    let(:data) do
      {
        'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
        'email' => 'darth@vader.sv'
      }
    end

    describe '#serialize' do
      let(:user_registered) { DefaultEvent.new(data: data) }

      subject { described_class.new.serialize(user_registered) }

      it 'returns serialized event' do
        expect(subject).to be_kind_of(EventStoreClient::Event)
        expect(subject.data).to eq(JSON.generate(data))
        expect(subject.metadata).to include('created_at')
        expect(subject.type).to eq('DefaultEvent')
      end
    end

    describe '#deserialize' do
      context 'when the event type const exists' do
        let(:event) { SerializedDefaultEvent.new(type: 'DefaultEvent') }
        subject { described_class.new.deserialize(event) }

        it 'returns instance of DefaultEvent' do
          expect(subject).to be_kind_of(DefaultEvent)
          expect(subject.data).to eq(data)
          expect(subject.metadata['created_at']).not_to be_nil
          expect(subject.type).to eq('DefaultEvent')
        end

        it 'skips validation' do
          expect_any_instance_of(DefaultEvent).to(
            receive(:initialize).with(hash_including(skip_validation: true))
          )
          subject
        end
      end

      context 'when the event type const does not exist' do
        let(:event) { SerializedDefaultEvent.new(type: 'SomethingHappened') }

        subject { described_class.new.deserialize(event) }

        it 'returns instance of DeserializedEvent' do
          expect(subject).to be_kind_of(DeserializedEvent)
          expect(subject.data).to eq(data)
          expect(subject.metadata['created_at']).not_to be_nil
          expect(subject.type).to eq('SomethingHappened')
        end
      end
    end
  end
end

class DefaultEvent < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:email).value(:string)
    end
  end
end

class SerializedDefaultEvent
  attr_reader :type, :id, :title

  def metadata
    '{"created_at":"2019-12-05 19:37:38 +0100"}'
  end

  def data
    '{"user_id":"dab48d26-e4f8-41fc-a9a8-59657e590716","email":"darth@vader.sv"}'
  end

  private

  def initialize(type:)
    @type = type
  end
end
