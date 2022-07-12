# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Streams::Subscribe do
  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::GRPC::Commands::Command) }
  it 'uses correct params class' do
    expect(instance.request).to eq(EventStore::Client::Streams::ReadReq)
  end
  it 'uses correct service' do
    expect(instance.service).to be_a(EventStore::Client::Streams::Streams::Stub)
  end

  describe '#call' do
    subject do
      Thread.new do
        instance.call(
          stream_name,
          handler: handler,
          options: options,
          skip_deserialization: skip_deserialization,
          skip_decryption: skip_decryption
        )
      end
    end

    let(:stream_name) { "some-stream$#{SecureRandom.uuid}" }
    let(:handler) do
      proc { |response| responses.push(response) }
    end
    let(:options) { {} }
    let(:skip_deserialization) { true }
    let(:skip_decryption) { false }
    let(:responses) { [] }
    let(:event) do
      EventStoreClient::DeserializedEvent.new(
        id: SecureRandom.uuid, type: 'some-event', data: { foo: :bar }
      )
    end

    after do
      subject.kill
    end

    it 'triggers handler when new event arrives' do
      subject
      sleep 0.5
      expect {
        EventStoreClient.client.append_to_stream(stream_name, [event]); sleep 0.5
      }.to change { responses.size }.by(1)
    end

    describe 'received events' do
      subject do
        thread = super()
        # Wait for subscription to initialize and receive it first event
        sleep 0.5
        # Append our own event and wait for it to arrive into our accumulator
        EventStoreClient.client.append_to_stream(stream_name, [event])
        thread
      end

      it 'contains confirmation event' do
        subject
        sleep 0.5
        expect(responses.first.success.confirmation).to(
          be_a(EventStore::Client::Streams::ReadResp::SubscriptionConfirmation)
        )
      end
      it 'contains the event, sent by us' do
        subject
        sleep 0.5
        expect(responses.last.success.event.event.id.string).to eq(event.id)
      end
    end

    describe 'subscribing on $all' do
      let(:stream_name) { '$all' }
      let(:options) { { filter: { stream_identifier: { prefix: [event_stream_name] } } } }
      let(:event_stream_name) {"some-stream$#{SecureRandom.uuid}"  }

      it 'triggers handler when new event arrives' do
        subject
        sleep 0.5
        expect {
          EventStoreClient.client.append_to_stream(event_stream_name, [event]); sleep 0.5
        }.to change { responses.size }.by(1)
      end

      describe 'received events' do
        subject do
          thread = super()
          # Wait for subscription to initialize and receive it first event
          sleep 0.5
          # Append our own event and wait for it to arrive into our accumulator
          EventStoreClient.client.append_to_stream(event_stream_name, [event])
          thread
        end

        it 'contains confirmation event' do
          subject
          sleep 0.5
          expect(responses.first.success.confirmation).to(
            be_a(EventStore::Client::Streams::ReadResp::SubscriptionConfirmation)
          )
        end
        it 'contains the event, sent by us' do
          subject
          sleep 0.5
          meaningful_events = responses.map(&:success).select {|r| r.event&.event }
          expect(meaningful_events.last.event.event.id.string).to eq(event.id)
        end
      end
    end
  end
end
