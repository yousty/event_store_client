# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Discover do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe '.current_member' do
    subject { described_class.current_member }

    it 'returns current member' do
      is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member)
    end
    it 'memorizes result' do
      expect(subject.__id__).to eq(described_class.current_member.__id__)
    end

    context 'when current member is failed endpoint' do
      let(:member) { EventStoreClient::GRPC::Cluster::Member.new(failed_endpoint: true) }

      before do
        described_class.instance_variable_set(:@current_member, member)
        allow(described_class).to receive(:new).and_return(instance)
        allow(instance).to receive(:call).and_call_original
      end

      it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member) }
      it 'looks up another member' do
        expect(subject.options_hash).not_to eq(member.options_hash)
      end
      it 'considers failed endpoint member during lookup' do
        subject
        expect(instance).to have_received(:call).with(failed_member: member)
      end
    end

    describe 'in threads' do
      subject { threads.each(&:join) }

      let(:threads) do
        5.times.map do
          Thread.new do
            Thread.current.report_on_exception = false
            Thread.current.thread_variable_set(:current_member, described_class.current_member)
          end
        end
      end

      before do
        allow(described_class).to receive(:new).and_return(instance)
        allow(instance).to receive(:call).and_wrap_original do |original_method, *args, **kwargs, &blk|
          sleep 0.1 # add some delay to allow all threads to arrive at the same point
          original_method.call(*args, **kwargs, &blk)
        end
      end

      it 'performs discover only once' do
        subject
        expect(instance).to have_received(:call).once
      end
      it 'sets the same result for all threads' do
        subject
        members = threads.map { |t| t.thread_variable_get(:current_member) }
        aggregate_failures do
          expect(members).to all be_a(EventStoreClient::GRPC::Cluster::Member)
          expect(members).to all satisfy('be the same object') { |m|
            m.__id__ == members.first.__id__
          }
        end
      end

      context 'when exception raises' do
        subject do
          threads.map do |t|
            t.join
          rescue error_class => e
            e
          else
            t.thread_variable_get(:current_member)
          end
        end

        let!(:error_class) { Class.new(StandardError) }

        before do
          stub_const('DiscoverError', error_class)
          times_method_being_called = 0
          allow(instance).to receive(:call).and_wrap_original do |original_method, *args, **kwargs, &blk|
            sleep 0.1 # add some delay to allow all threads to arrive at the same point
            times_method_being_called += 1
            # First call to instance#call should raise error. All further calls should return normal
            # result
            raise error_class if times_method_being_called == 1
            original_method.call(*args, **kwargs, &blk)
          end
        end

        it 'tries to perform discover only once' do
          subject
          expect(instance).to have_received(:call).once
        end
        it 'raises error in all threads' do
          expect(subject).to all be_a(DiscoverError)
        end
        it 'does not raise on further calls when error is gone' do
          subject
          expect { described_class.current_member }.not_to raise_error
        end
      end
    end
  end

  describe '.member_alive?' do
    subject { described_class.member_alive? }

    let(:member) { EventStoreClient::GRPC::Cluster::Member.new }

    context 'when current member is not set' do
      it { is_expected.to eq(false) }
    end

    context 'when current member set' do
      before do
        described_class.instance_variable_set(:@current_member, member)
      end

      context 'when it is ok' do
        it { is_expected.to be_truthy }
      end

      context 'when is is failed endpoint' do
        before do
          member.failed_endpoint = true
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#call' do
    subject { instance.call }

    let(:gossip_discover) { EventStoreClient::GRPC::Cluster::GossipDiscover.new }
    let(:queryless_discover) { EventStoreClient::GRPC::Cluster::QuerylessDiscover.new }

    before do
      allow(EventStoreClient::GRPC::Cluster::GossipDiscover).to(
        receive(:new).and_return(gossip_discover)
      )
      allow(EventStoreClient::GRPC::Cluster::QuerylessDiscover).to(
        receive(:new).and_return(queryless_discover)
      )
      allow(gossip_discover).to receive(:call).and_call_original
      allow(queryless_discover).to receive(:call).and_call_original
    end

    context 'when gossip discover is needed' do
      before do
        EventStoreClient.config.eventstore_url = 'esdb+discover://localhost:2111/?tls=true'
      end

      it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member) }
      it 'performs gossip discover' do
        subject
        expect(gossip_discover).to(
          have_received(:call).
            with(
              [EventStoreClient::Connection::Url::Node.new('localhost', 2111)],
              failed_member: nil
            )
        )
      end

      context 'when failed member is provided' do
        subject { instance.call(failed_member: member) }

        let(:member) { EventStoreClient::GRPC::Cluster::Member.new }

        it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member) }
        it 'performs gossip discover by taking into account failed endpoint' do
          subject
          expect(gossip_discover).to(
            have_received(:call).
              with(
                [EventStoreClient::Connection::Url::Node.new('localhost', 2111)],
                failed_member: member
              )
          )
        end
      end

      context 'when nodes cluster is given' do
        before do
          EventStoreClient.config.eventstore_url = 'esdb://localhost:2111,localhost:2112/?tls=true'
        end

        it { is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member) }
        it 'performs gossip discover by taking into account all nodes' do
          subject
          expect(gossip_discover).to(
            have_received(:call).
              with(
                [
                  EventStoreClient::Connection::Url::Node.new('localhost', 2111),
                  EventStoreClient::Connection::Url::Node.new('localhost', 2112),
                ],
                failed_member: nil
              )
          )
        end
      end
    end

    context 'when gossip discover is not needed' do
      before do
        EventStoreClient.config.eventstore_url = 'esdb://some.host:3002'
      end

      it 'performs queryless discover' do
        subject
        expect(queryless_discover).to(
          have_received(:call).
            with(
              [EventStoreClient::Connection::Url::Node.new('some.host', 3002)]
            )
        )
      end
    end
  end
end
