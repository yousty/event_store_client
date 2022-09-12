# frozen_string_literal: true

RSpec.describe EventStoreClient::GRPC::Cluster::GossipDiscover do
  subject { instance }

  let(:instance) { described_class.new }

  it { is_expected.to be_a(EventStoreClient::Configuration) }

  describe 'constants' do
    describe 'ALLOWED_NODE_STATES' do
      subject { described_class::ALLOWED_NODE_STATES }

      it 'has correctly ordered value' do
        is_expected.to eq(%i(Leader Follower ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless))
      end
      it { is_expected.to be_frozen }
    end

    describe 'READ_ONLY_STATES' do
      subject { described_class::READ_ONLY_STATES }

      it 'has correctly ordered value' do
        is_expected.to eq(%i(ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless))
      end
      it { is_expected.to be_frozen }
    end

    describe 'DiscoverError' do
      subject { described_class::DiscoverError }

      it { is_expected.to be < StandardError }
    end
  end

  describe '#call' do
    subject { instance.call(nodes, failed_member: failed_member) }

    let(:hosts) { [] }
    let(:nodes) do
      hosts.map do |host_with_port|
        host = host_with_port.split(':').first
        port = host_with_port.split(':').last.to_i
        EventStoreClient::Connection::Url::Node.new(host, port)
      end
    end
    let(:failed_member) { nil }
    let(:retries_number) { 2 }

    before do
      EventStoreClient.config.eventstore_url.max_discover_attempts = retries_number
      allow(instance).to receive(:node_members).and_call_original
    end

    shared_examples 'nodes lookup order' do
      let(:order) { [] }

      before do
        EventStoreClient.config.eventstore_url.max_discover_attempts = 1
        allow(instance).to receive(:node_members).and_wrap_original do |original_method, node|
          order.push(node)
          original_method.call(node)
        end
      end

      it 'look ups nodes in correct order' do
        subject rescue
        expect(order).to eq(expected_order)
      end
    end

    context 'when nodes are absent' do
      it 'raises error' do
        expect { subject }.to raise_error(described_class::DiscoverError, /Failed to discover/)
      end
      it 'does not perform members lookup' do
        subject rescue
        expect(instance).not_to have_received(:node_members)
      end
    end

    context 'when nodes are present' do
      let(:hosts) { ['localhost:3000', 'localhost:3001'] }

      context 'when nodes are unreachable' do
        it 'raises error' do
          expect { subject }.to raise_error(described_class::DiscoverError, /Failed to discover/)
        end
        it 'tries to get members of first node' do
          subject rescue
          expect(instance).to(
            have_received(:node_members).with(nodes.first).exactly(retries_number)
          )
        end
        it 'tries to get members of second node' do
          subject rescue
          expect(instance).to(
            have_received(:node_members).with(nodes.first).exactly(retries_number)
          )
        end
        it_behaves_like 'nodes lookup order' do
          let(:expected_order) { nodes }
        end
      end

      context 'when first node has the same host and port as failed member' do
        let(:failed_member) do
          EventStoreClient::GRPC::Cluster::Member.new(
            host: nodes.first.host, port: nodes.first.port
          )
        end

        it_behaves_like 'nodes lookup order' do
          let(:expected_order) { [nodes.last, nodes.first] }
        end
      end

      context 'when first node is reachable' do
        let(:hosts) { ['localhost:2115', 'localhost:3000'] }

        it 'returns suitable member' do
          is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member)
        end
        it 'does not try to lookup members of second host' do
          subject
          expect(instance).not_to have_received(:node_members).with(nodes.last)
        end
      end

      describe 'look up in the nodes cluster' do
        let(:hosts) { ['localhost:2111', 'localhost:2112', 'localhost:2113'] }

        before do
          EventStoreClient.config.eventstore_url.tls = true
        end

        it 'returns suitable member' do
          is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member)
        end
        it 'has proper attributes' do
          aggregate_failures do
            expect(subject.host).to eq('127.0.0.1')
            expect(subject.state).to eq(:Leader)
            expect(subject.active).to eq(true)
            expect(subject.instance_id).to be_a(String)
          end
        end

        describe 'preference of members in non-Leader state' do
          before do
            EventStoreClient.config.eventstore_url.node_preference = :Follower
          end

          it 'returns suitable member' do
            is_expected.to be_a(EventStoreClient::GRPC::Cluster::Member)
          end
          it 'has proper attributes' do
            aggregate_failures do
              expect(subject.host).to eq('127.0.0.1')
              expect(subject.state).to eq(:Follower)
              expect(subject.active).to eq(true)
              expect(subject.instance_id).to be_a(String)
            end
          end
        end
      end

      describe 'suitable member' do
        let(:hosts) { ['localhost:3000'] }
        let(:member_1) do
          EventStoreClient::GRPC::Cluster::Member.new(
            host: 'localhost', port: 2110, state: :Leader, active: true
          )
        end
        let(:member_2) do
          EventStoreClient::GRPC::Cluster::Member.new(
            host: 'localhost', port: 2111, state: :Follower, active: true
          )
        end
        let(:members) { [member_1, member_2] }
        let(:suitable_member) { member_1 }

        before do
          EventStoreClient.config.eventstore_url.node_preference = :Follower
          allow(instance).to receive(:node_members).and_return(members)
          allow(instance).to receive(:detect_suitable_member).and_return(suitable_member)
        end

        it 'returns member of correct node' do
          subject
          expect(instance).to have_received(:node_members).with(nodes.first)
        end
        it 'detects suitable member correctly' do
          subject
          expect(instance).to have_received(:detect_suitable_member).with(members)
        end
        it 'returns suitable member' do
          is_expected.to eq(suitable_member)
        end

        context 'when suitable member can not be detected' do
          let(:suitable_member) { nil }

          it 'raises error' do
            expect { subject }.to raise_error(described_class::DiscoverError, /Failed to discover/)
          end
        end
      end
    end
  end

  describe '#ordered_states' do
    subject { instance.send(:ordered_states) }

    context 'when node preference is :Leader' do
      it 'returns states in initial order' do
        is_expected.to eq(described_class::ALLOWED_NODE_STATES)
      end
    end

    context 'when node preference is :Follower' do
      before do
        EventStoreClient.config.eventstore_url.node_preference = :Follower
      end

      it 'prioritizes :Follower role' do
        is_expected.to(
          eq(
            %i(Follower Leader ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless)
          )
        )
      end
    end

    context 'when node preference is :ReadOnlyReplica' do
      before do
        EventStoreClient.config.eventstore_url.node_preference = :ReadOnlyReplica
      end

      it 'prioritizes read roles' do
        is_expected.to(
          eq(
            %i(ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless Leader Follower)
          )
        )
      end
    end
  end

  describe '#detect_suitable_member' do
    subject { instance.send(:detect_suitable_member, members) }

    let(:member_1) do
      EventStoreClient::GRPC::Cluster::Member.new(
        host: 'localhost', port: 2110, state: :Leader, active: true
      )
    end
    let(:member_2) do
      EventStoreClient::GRPC::Cluster::Member.new(
        host: 'localhost', port: 2111, state: :Follower, active: true
      )
    end
    let(:members) do
      [member_1, member_2]
    end

    before do
      EventStoreClient.config.eventstore_url.node_preference = :Follower
    end

    it 'returns member, based on node preference' do
      is_expected.to eq(member_2)
    end

    context 'when member by preference is not active' do
      before do
        member_2.active = false
      end

      it 'looks up among active members' do
        is_expected.to eq(member_1)
      end
    end

    context 'when members are not in the allowed list' do
      let(:members) do
        [
          EventStoreClient::GRPC::Cluster::Member.new(
            host: 'localhost', port: 2111, state: :CatchingUp, active: true
          )
        ]
      end

      it { is_expected.to be_nil }
    end
  end
end
