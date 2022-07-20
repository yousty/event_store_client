# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::LinkTo do
  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }

  describe '#call' do
    subject { instance.call(stream_name, event, options: options) }

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:other_stream_name) { "other-stream$#{SecureRandom.uuid}" }
    let(:options) { {} }
    let(:event) do
      event = EventStoreClient::DeserializedEvent.new(type: 'some-event', data: { foo: :bar })
      EventStoreClient.client.append_to_stream(other_stream_name, event)
      EventStoreClient.client.read(other_stream_name).success.first
    end

    it 'links event' do
      expect { subject }.to change { EventStoreClient.client.read(stream_name).success&.size }.to(1)
    end

    describe 'linked event' do
      subject { super(); EventStoreClient.client.read(stream_name).success.first }

      it 'has the same event id' do
        expect(subject.id).to eq(event.id)
      end
      it 'has special event property' do
        expect(subject.type).to eq('$>')
      end
      it 'resolves to the stream it was appended' do
        expect(subject.stream_name).to eq(stream_name)
      end
      it 'has its own title' do
        aggregate_failures do
          expect(subject.title).not_to be_empty
          expect(subject.title).to include(stream_name)
          expect(subject.title).not_to eq(event.title)
        end
      end
      it 'has the same position attributes' do
        aggregate_failures do
          expect(subject.commit_position).to eq(event.commit_position)
          expect(subject.prepare_position).to eq(event.prepare_position)
        end
      end
      it 'has proper metadata', timecop: true do
        expect(subject.metadata).to(
          include(
            'type' => '$>', 'created_at' => Time.now.to_s, 'content-type' => 'application/json'
          )
        )
      end
      it 'has proper data' do
        expect(subject.data).to eq('message' => event.title)
      end
    end
  end
end
