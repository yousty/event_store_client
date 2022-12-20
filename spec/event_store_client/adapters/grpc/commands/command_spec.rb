# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Commands::Command do
  subject { instance }

  let(:config) { EventStoreClient.config }
  let(:instance) { described_class.new(config: config, **conn_options) }
  let(:conn_options) { { host: 'localhost', port: 3000 } }

  it { is_expected.to be_a(Dry::Monads::Result::Mixin) }
  it { is_expected.to be_a(Dry::Monads::Try::Mixin) }

  describe '.use_request' do
    subject { described_class.use_request(request_class) }

    let(:request_class) { Class.new }

    it 'registers request class' do
      expect { subject }.to change {
        EventStoreClient::GRPC::CommandRegistrar.request(described_class)
      }.to(request_class)
    end
  end

  describe '.use_service' do
    subject { described_class.use_service(service_class) }

    let(:service_class) { Class.new }

    it 'registers request class' do
      expect { subject }.to change {
        EventStoreClient::GRPC::CommandRegistrar.service(described_class)
      }.to(service_class)
    end
  end

  describe '#call' do
    subject { instance.call }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#metadata' do
    subject { instance.metadata }

    let(:conn_options) { { username: 'some-user', password: '1234'} }

    describe 'when connection is secure' do
      before do
        EventStoreClient.config.eventstore_url.tls = true
      end

      it 'includes credentials into metadata' do
        credentials =
          Base64.
            encode64("#{conn_options[:username]}:#{conn_options[:password]}").
            delete("\n")
        is_expected.to eq('authorization' => "Basic #{credentials}")
      end
    end

    describe 'when connection is insecure' do
      it { is_expected.to eq({}) }
    end
  end

  describe '#request' do
    subject { instance.request }

    let(:request_class) { Class.new }

    before do
      described_class.use_request(request_class)
    end

    it 'returns request class' do
      is_expected.to eq(request_class)
    end
  end

  describe '#service' do
    subject { instance.service }

    let(:service_class) { EventStore::Client::Gossip::Gossip::Stub }

    before do
      described_class.use_service(service_class)
    end

    it 'returns instance of service class' do
      is_expected.to be_an_instance_of(service_class)
    end
  end

  describe '#connection_options' do
    subject { instance.connection_options }

    it { is_expected.to eq(instance.send(:connection).options_hash) }
  end

  describe '#retry_request' do
    subject { instance.send(:retry_request, &blk) }

    let(:blk) { proc { result } }
    let(:result) { 'some-result' }

    context 'when no errors raises' do
      it 'returns result' do
        is_expected.to eq(result)
      end
    end

    context 'when raises error' do
      let(:result) { request.call }
      let(:request) { double('Request') }
      let(:error_class) { GRPC::Unavailable }

      before do
        allow(request).to receive(:call).and_raise(error_class)
      end

      context 'when GRPC::Unavailable error raises' do
        it 'retries request up to config.eventstore_url.grpc_retry_attempts times' do
          begin
            subject
          rescue error_class
          end
          expect(request).to(
            have_received(:call).
              exactly(EventStoreClient.config.eventstore_url.grpc_retry_attempts + 1)
          )
        end
        it 'raises that error' do
          expect { subject }.to raise_error(error_class)
        end
        it 'marks current member as failed endpoint' do
          member = EventStoreClient::GRPC::Discover.current_member(config: config)
          expect {
            begin
              subject
            rescue error_class
            end
          }.to change { member.failed_endpoint }.from(false).to(true)
        end

        context 'when request succeeds after several attempts' do
          let(:result_after_attempts) { 'some-result' }

          before do
            attempt = 0
            allow(request).to receive(:call) do
              if EventStoreClient.config.eventstore_url.grpc_retry_attempts - 1 == attempt
                result_after_attempts
              else
                attempt += 1
                raise error_class
              end
            end
          end

          it 'returns that final result' do
            is_expected.to eq(result_after_attempts)
          end
          it 'performs retries' do
            begin
              subject
            rescue error_class
            end
            expect(request).to have_received(:call).at_least(:twice)
          end
        end
      end

      context 'when unhandled error raises' do
        let(:error_class) { Class.new(StandardError) }

        it 'raises it' do
          expect { subject }.to raise_error(error_class)
        end
        it 'does not perform retries' do
          begin
            subject
          rescue error_class
          end
          expect(request).to have_received(:call).once
        end
      end
    end
  end
end
