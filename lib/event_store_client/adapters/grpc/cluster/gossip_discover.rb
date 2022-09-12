# frozen_string_literal: true

require 'event_store_client/adapters/grpc/generated/shared_pb'
require 'event_store_client/adapters/grpc/generated/gossip_pb'
require 'event_store_client/adapters/grpc/generated/gossip_services_pb'

module EventStoreClient
  module GRPC
    module Cluster
      class GossipDiscover
        include Configuration

        DiscoverError = Class.new(StandardError)

        # Order is important - it plays role of states priority as well
        READ_ONLY_STATES = %i[ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless].freeze
        ALLOWED_NODE_STATES =
          (%i[Leader Follower] + READ_ONLY_STATES).freeze

        # @param nodes [Array<EventStoreClient::Connection::Url::Node>]
        # @param failed_member [EventStoreClient::GRPC::Cluster::Member, nil]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        # @raise [EventStoreClient::GRPC::Cluster::GossipDiscover::DiscoverError]
        def call(nodes, failed_member:)
          nodes = sort_nodes(nodes, failed_member)

          attempts = config.eventstore_url.max_discover_attempts
          attempts.times do
            nodes.each do |node|
              suitable_member = suitable_member_of_node(node)
              next unless suitable_member

              return suitable_member
            end

            sleep(config.eventstore_url.discover_interval / 1000.0)
          end

          raise DiscoverError, "Failed to discover suitable host after #{attempts} attempts."
        end

        private

        # @return [Array<Symbol>]
        def ordered_states
          @ordered_states ||=
            # Move preferred state to the first place
            case config.eventstore_url.node_preference
            when :Leader, :Follower
              [config.eventstore_url.node_preference] +
              (ALLOWED_NODE_STATES - [config.eventstore_url.node_preference])
            else
              READ_ONLY_STATES + (ALLOWED_NODE_STATES - READ_ONLY_STATES)
            end
        end

        # @param node [EventStoreClient::Connection::Url::Node]
        # @return [Array<EventStoreClient::GRPC::Cluster::Member>, nil]
        def node_members(node)
          connection = Connection.new(
            host: node.host,
            port: node.port,
            timeout: config.eventstore_url.gossip_timeout
          )
          members =
            connection.
            call(EventStore::Client::Gossip::Gossip::Stub).
            read(EventStore::Client::Empty.new).
            members
          members.map do |member|
            Member.new(
              host: member.http_end_point.address,
              port: member.http_end_point.port,
              state: member.state,
              active: member.is_alive,
              instance_id: Utils.uuid_to_str(member.instance_id)
            )
          end
        rescue ::GRPC::BadStatus, Errno::ECONNREFUSED
          config.logger&.debug("Failed to get cluster list from #{node.host}:#{node.port} node.")
          nil
        end

        # Pick a suitable member based on its status and node preference
        # @return [Array<EventStoreClient::GRPC::Cluster::Member>]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        def detect_suitable_member(members)
          members = members.select(&:active)
          members = members.select { |member| ALLOWED_NODE_STATES.include?(member.state) }
          members = members.sort_by { |member| ordered_states.index(member.state) }
          members.first
        end

        # Put failed node to the end of the list
        # @param nodes [Array<EventStoreClient::Connection::Url::Node>]
        # @param failed_member [EventStoreClient::GRPC::Cluster::Member, nil]
        # @return [Array<EventStoreClient::Connection::Url::Node>]
        def sort_nodes(nodes, failed_member)
          return nodes unless failed_member

          nodes.sort_by do |node|
            failed_member.host == node.host && failed_member.port == node.port ? 1 : 0
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

        # Searches a suitable member among members of the given node
        # @param node [EventStoreClient::Connection::Url::Node]
        # @return [EventStoreClient::GRPC::Cluster::Member, nil]
        def suitable_member_of_node(node)
          config.logger&.debug(
            "Starting to discover #{node.host}:#{node.port} node for candidates."
          )
          members = node_members(node)
          return unless members

          suitable_member = detect_suitable_member(members)
          return unless suitable_member

          config.logger&.debug(
            "Found suitable member: #{suitable_member.host}:#{suitable_member.port} with " \
            "role \"#{suitable_member.state}\"."
          )
          suitable_member
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      end
    end
  end
end
