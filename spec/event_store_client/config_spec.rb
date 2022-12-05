# frozen_string_literal: true

RSpec.describe EventStoreClient::Config do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Extensions::OptionsExtension) }

  describe 'constants' do
    describe 'CHANNEL_ARGS_DEFAULTS' do
      subject { described_class::CHANNEL_ARGS_DEFAULTS }

      it do
        is_expected.to(
          eq(
            'grpc.min_reconnect_backoff_ms' => 100,
            'grpc.max_reconnect_backoff_ms' => 100,
            'grpc.initial_reconnect_backoff_ms' => 100
          )
        )
      end
      it { is_expected.to be_frozen }
    end
  end

  describe 'options' do
    it { is_expected.to have_option(:per_page).with_default_value(20) }
    it do
      is_expected.to(
        have_option(:default_event_class).with_default_value(EventStoreClient::DeserializedEvent)
      )
    end
    it { is_expected.to have_option(:logger) }
    it { is_expected.to have_option(:eventstore_url) }
    it { is_expected.to have_option(:mapper) }
    it { is_expected.to have_option(:skip_deserialization).with_default_value(false) }
    it { is_expected.to have_option(:skip_decryption).with_default_value(false) }
    it { is_expected.to have_option(:channel_args) }

    describe 'eventstore_url default value' do
      subject { instance.eventstore_url }

      it 'has correct value' do
        is_expected.to(
          eq(EventStoreClient::Connection::UrlParser.new.call('esdb://localhost:2113'))
        )
      end
    end

    describe 'mapper default value' do
      subject { instance.mapper }

      it { is_expected.to be_a(EventStoreClient::Mapper::Default) }
    end

    describe 'channel_args default value' do
      subject { instance.channel_args }

      it 'has correct value' do
        is_expected.to(
          eq(
            'grpc.min_reconnect_backoff_ms' => 100,
            'grpc.max_reconnect_backoff_ms' => 100,
            'grpc.initial_reconnect_backoff_ms' => 100,
            'grpc.enable_retries' => 0
          )
        )
      end

      context 'when custom value for those keys are provided' do
        before do
          instance.channel_args = { 'grpc.max_reconnect_backoff_ms' => 300}
        end

        it 'reverse-merges them' do
          is_expected.to(
            eq(
              'grpc.min_reconnect_backoff_ms' => 100,
              'grpc.max_reconnect_backoff_ms' => 300,
              'grpc.initial_reconnect_backoff_ms' => 100,
              'grpc.enable_retries' => 0
            )
          )
        end
      end

      context 'when custom value for "grpc.enable_retries" setting is provided' do
        before do
          instance.channel_args = { 'grpc.enable_retries' => 1 }
        end

        it 'ignores it' do
          is_expected.to(
            eq(
              'grpc.min_reconnect_backoff_ms' => 100,
              'grpc.max_reconnect_backoff_ms' => 100,
              'grpc.initial_reconnect_backoff_ms' => 100,
              'grpc.enable_retries' => 0
            )
          )
        end
      end

      context 'when key in the custom hash is provided as symbol' do
        before do
          instance.channel_args = { 'grpc.max_reconnect_backoff_ms': 300}
        end

        it 'transforms it into a string' do
          is_expected.to(
            eq(
              'grpc.min_reconnect_backoff_ms' => 100,
              'grpc.max_reconnect_backoff_ms' => 300,
              'grpc.initial_reconnect_backoff_ms' => 100,
              'grpc.enable_retries' => 0
            )
          )
        end
      end
    end
  end
end
