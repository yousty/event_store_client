# frozen_string_literal: true

require 'spec_helper'
require 'event_store_client/adapters/grpc/client'
require 'event_store_client/adapters/grpc/commands/streams/append'

RSpec.describe EventStoreClient::GRPC::Client do
  subject { described_class.new.append_to_stream(stream_name, [event], options: options) }

  let(:stream_name) { 'stream_name' }
  let(:options) { {} }

  describe '#append_to_stream' do
    let(:event) { instance_spy(EventStoreClient::Event) }
    let(:result) { Dry::Monads::Success }
    let(:cmd_class) { EventStoreClient::GRPC::Commands::Streams::Append }
    let(:cmd) { instance_spy(cmd_class, call: result) }

    before do
      allow(cmd_class).to receive(:new).and_return(cmd)
      allow(event).to receive(:is_a?).with(EventStoreClient::Event).and_return(true)
    end

    it 'calls append to stream command with correct arguments' do
      subject

      expect(cmd).to have_received(:call).with(
        stream_name, [event], options: options
      )
    end

    it 'returns Success' do
      expect(subject).to eq(result)
    end

    context 'when command fails' do
      let(:result) { Dry::Monads::Failure }

      it 'returns Failure' do
        expect(subject).to eq(result)
      end
    end
  end
end

