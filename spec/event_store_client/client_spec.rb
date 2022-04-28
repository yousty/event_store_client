# frozen_string_literal: true

RSpec.describe EventStoreClient::Client do
  let(:client) { described_class.new }
  let(:stream_name) { 'stream_name' }
  let(:options) { {} }

  shared_examples 'argument error' do
    it 'raises ArgumentError' do
      expect { client.append_to_stream(stream_name, event, options) }.to(
        raise_error(ArgumentError)
      )
    end
  end

  describe '#append_to_stream' do
    let(:event) { double('Event') }

    context 'when stream_name is nil' do
      let(:stream_name) { nil }

      it_behaves_like 'argument error'
    end

    context 'when stream_name is empty' do
      let(:stream_name) { '' }

      it_behaves_like 'argument error'
    end

    context 'when event is not of class Event' do
      let(:event) { 'A String' }

      it_behaves_like 'argument error'
    end
  end

  describe '#read_stream' do
    it 'raises AbstractMethodError' do
      expect { client.read_stream }.to raise_error(EventStoreClient::AbstractMethodError)
    end
  end

  describe '#subscribe_to_stream' do
    it 'raises AbstractMethodError' do
      expect { client.subscribe_to_stream }.to raise_error(EventStoreClient::AbstractMethodError)
    end
  end

  describe '#subscribe_to_all' do
    it 'raises AbstractMethodError' do
      expect { client.subscribe_to_all }.to raise_error(EventStoreClient::AbstractMethodError)
    end
  end
end


# require 'support/encrypted_event'
# module EventStoreClient
#   RSpec.describe Client do
#     let(:client) { described_class.new }
#     let(:event) { SomethingHappened.new(data: { foo: 'bar' }, metadata: {}) }

#     let(:store_adapter) { client.connection }

#     describe '#publish' do
#       it 'publishes events to the store' do
#         client.publish(stream: 'stream', events: [event])
#         expect(store_adapter.event_store['stream'].length).to eq(1)
#         client.publish(stream: 'stream', events: [event])
#         expect(store_adapter.event_store['stream'].length).to eq(2)
#       end
#     end

#     describe '#read' do
#       let(:events) do
#         [
#           Event.new(type: 'SomethingHappened', data: { foo: 'bar' }.to_json),
#           Event.new(type: 'SomethingElseHappened', data: { foo: 'bar' }.to_json)
#         ]
#       end

#       before do
#         store_adapter.append_to_stream('stream', events)
#       end

#       context 'forward' do
#         it 'reads events from a stream' do
#           events = client.read('stream').value!
#           expect(events.count).to eq(2)
#           expect(events.map(&:type)).
#             to eq(%w[SomethingHappened SomethingElseHappened])
#         end
#       end

#       context 'backward' do
#         it 'reads events from a stream' do
#           events = client.read('stream', options: { direction: 'backard', start: 'head' }).value!
#           expect(events.count).to eq(2)
#           expect(events.map(&:type)).
#             to eq(%w[SomethingHappened SomethingElseHappened])
#         end
#       end

#       context 'all' do
#         it 'reads all events from a stream' do
#           events = client.read('stream', options: { all: true }).value!
#           expect(events.count).to eq(2)
#           expect(events.map(&:type)).
#             to eq(%w[SomethingHappened SomethingElseHappened])
#         end
#       end

#       context 'when encrypted mapper' do
#         let(:encdypted_data) do
#           {
#             data: {
#               user_id: SecureRandom.uuid,
#               first_name: 'es_encrypted',
#               last_name: 'es_encrypted',
#               profession: 'es_encrypted'
#             }
#           }
#         end

#         let(:decrypted_data) do
#           {

#             user_id: SecureRandom.uuid,
#             first_name: 'John',
#             last_name: 'Done',
#             profession: 'Bos'
#           }
#         end

#         let(:events) { [EncryptedEvent.new(encdypted_data)] }

#         let(:key_repository) { double }
#         let(:encrypted_mapper) { EventStoreClient::Mapper::Encrypted.new(key_repository) }

#         before do
#           allow_any_instance_of(EventStoreClient.adapter.class).to receive(
#             :mapper
#           ).and_return(encrypted_mapper)
#           allow_any_instance_of(EventStoreClient::DataDecryptor).to receive(
#             :call
#           ).and_return(decrypted_data)
#         end

#         context 'when skip decryption set to true' do
#           let(:options) { { skip_decryption: true } }

#           it 'returns non decrypted events' do
#             expect_any_instance_of(EventStoreClient::DataDecryptor).to_not receive(:call)
#             events = client.read('stream', options: options).value!
#             expect(events.count).to eq(1)
#             expect(events.map(&:type)).to eq(%w[EncryptedEvent])
#           end
#         end

#         context 'when skip decryption set to false' do
#           let(:options) { { skip_decryption: false } }

#           it 'returns non decrypted events' do
#             expect_any_instance_of(EventStoreClient::DataDecryptor).to receive(:call)
#             events = client.read('stream', options: options).value!
#             expect(events.count).to eq(1)
#             expect(events.map(&:type)).to eq(%w[EncryptedEvent])
#           end
#         end
#       end
#     end

#     describe '#link_to' do
#       subject { -> { client.link_to(stream: stream_name, events: events) } }

#       let(:event_1) { Event.new(type: 'SomethingHappened', data: {}.to_json) }
#       let(:stream_name) { :stream_name }
#       let(:events) { [event_1] }

#       before do
#         allow_any_instance_of(InMemory).to receive(:link_to).with(
#           stream_name,
#           events,
#           options: {}
#         ).and_return(Success())
#       end

#       shared_examples 'argument error' do
#         it 'raises an Argument error' do
#           expect { subject.call }.to raise_error(ArgumentError)
#         end
#       end

#       shared_examples 'correct linking events' do
#         it 'invokes link event for the store' do
#           expect_any_instance_of(InMemory).to receive(:link_to).with(
#             stream_name,
#             events,
#             options: {}
#           )

#           subject.call
#         end

#         it 'returns events' do
#           expect(subject.call).to be_truthy
#         end
#       end

#       context 'when missing stream' do
#         let(:stream_name) { nil }
#         it_behaves_like 'argument error'
#       end

#       context 'when missing events' do
#         let(:events) { [] }
#         it_behaves_like 'argument error'
#       end

#       context 'when passed single event' do
#         let(:events) { event_1 }
#         it_behaves_like 'correct linking events'
#       end

#       it_behaves_like 'correct linking events'
#     end

#     describe 'subscribe' do
#     end
#   end
# end
