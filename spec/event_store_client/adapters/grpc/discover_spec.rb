# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Discover do
  subject { instance }

  let(:instance) { described_class.new(config: config) }
  let(:config) { EventStoreClient.config }

  describe '.current_member' do
    subject { described_class.current_member(config: config) }

    it 'returns current member' do
      is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member)
    end
    it 'memorizes result' do
      expect(subject.__id__).to eq(described_class.current_member(config: config).__id__)
    end

    context 'when current member is failed endpoint' do
      let(:member) { EventStoreClient::GRPC::Cluster::Member.new(failed_endpoint: true) }

      before do
        described_class.instance_variable_set(:@current_member, { default: member })
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
            Thread.current.thread_variable_set(
              :current_member,
              described_class.current_member(config: config)
            )
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
          expect { described_class.current_member(config: config) }.not_to raise_error
        end
      end
    end

    describe 'with multiple configs' do
      let!(:config1) do
        EventStoreClient.configure do |config|
          config.eventstore_url = url1
        end
      end
      let!(:config2) do
        EventStoreClient.configure(name: :another_config) do |config|
          config.eventstore_url = url2
        end
      end
      let(:url1) { 'esdb://admin:changeit@localhost:2111,localhost:2112,localhost:2113' }
      let(:url2) { 'esdb://admin:changeit@localhost:2115/?tls=false' }
      let(:read_worker1) do
        Thread.new do
          client = EventStoreClient.client
          client.read('$all', options: { max_count: 1 })
        end
      end
      let(:read_worker2) do
        Thread.new do
          client = EventStoreClient.client(config_name: :another_config)
          client.read('$all', options: { max_count: 1 })
        end
      end
      let(:locks) { described_class.instance_variable_get(:@semaphore) }
      let(:result) { {} }

      before do
        allow(described_class).to receive(:new).and_wrap_original do |orig_method, *args, **kwargs, &blk|
          res = orig_method.call(*args, **kwargs, &blk)
          sleep 0.2 # Wait all Mutexes to initialize
          config = res.send(:config)
          locks = described_class.instance_variable_get(:@semaphore)
          result[config.name] = {
            default: locks[:default].owned?, another_config: locks[:another_config].owned?
          }
          # Simulate payload to wait for both clients to reach the same point of execution
          sleep 0.5
          res
        end
      end

      it 'does not block discovery of different clients' do
        read_worker1
        read_worker2
        sleep 0.5
        locks = described_class.instance_variable_get(:@semaphore)
        aggregate_failures do
          expect(locks).to(
            match(
              hash_including(
                default: instance_of(Thread::Mutex),
                another_config: instance_of(Thread::Mutex)
              )
            )
          )
          expect(locks.values).to all be_locked
        end
        read_worker1.exit
        read_worker2.exit
      end
      it 'uses separated locks for different clients' do
        read_worker1
        read_worker2
        sleep 0.5
        aggregate_failures do
          expect(result[:default][:default]).to(
            eq(true), "Expect :default config to be locked using :default Mutex"
          )
          expect(result[:default][:another_config]).to(
            eq(false), "Expect :default config to not to be locked using :another_config Mutex"
          )
          expect(result[:another_config][:default]).to(
            eq(false), "Expect :another_config config to not to be locked using :default Mutex"
          )
          expect(result[:another_config][:another_config]).to(
            eq(true), "Expect :another_config config to be locked using :another_config Mutex"
          )
        end
        read_worker1.exit
        read_worker2.exit
      end
      it 'resolves member for different configs correctly' do
        [read_worker1, read_worker2].each(&:join)
        members = described_class.instance_variable_get(:@current_member)
        aggregate_failures do
          expect(members[:default].host).to eq('127.0.0.1')
          expect(members[:default].port).to satisfy { |port| [2111, 2112, 2113].include?(port) }
          expect(members[:another_config].host).to eq('localhost')
          expect(members[:another_config].port).to eq(2115)
        end
      end
    end
  end

  describe '.member_alive?' do
    subject { described_class.member_alive?(member) }

    let(:member) { nil }

    context 'when current member is not set' do
      it { is_expected.to eq(false) }
    end

    context 'when current member set' do
      let(:member) { EventStoreClient::GRPC::Cluster::Member.new }

      before do
        described_class.instance_variable_set(:@current_member, { default: member })
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

    let(:gossip_discover) { EventStoreClient::GRPC::Cluster::GossipDiscover.new(config: config) }
    let(:queryless_discover) do
      EventStoreClient::GRPC::Cluster::QuerylessDiscover.new(config: config)
    end

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
        config.eventstore_url = 'esdb+discover://localhost:2111/?tls=true'
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
          config.eventstore_url = 'esdb://localhost:2111,localhost:2112/?tls=true'
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
        config.eventstore_url = 'esdb://some.host:3002'
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
