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
        ALLOWED_NODE_STATES =
          %i(Leader Follower ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless).freeze

        # @param nodes [Array<EventStoreClient::Connection::Url::Node>]
        # @param failed_member [EventStoreClient::GRPC::Cluster::Member, nil]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        # @raise [EventStoreClient::GRPC::Cluster::GossipDiscover::DiscoverError]
        def call(nodes, failed_member:)
          # Put failed node to the end of the list
          nodes = nodes.sort do |node|
            failed_member.host == node.host && failed_member.port == node.port ? 1 : 0
          end if failed_member

          attempts = config.eventstore_url.max_discover_attempts
          attempts.times do
            nodes.each do |node|
              config.logger&.debug(
                "Starting to discover #{node.host}:#{node.port} node for candidates."
              )
              members = node_members(node)
              next unless members

              members.select!(&:active)
              members.select! { |member| ALLOWED_NODE_STATES.include?(member.state) }
              members.sort! { |member| ordered_states.index(member.state) }
              suitable_member = members.first
              if suitable_member
                config.logger&.debug(
                  "Found suitable member: #{suitable_member.host}:#{suitable_member.port} with"\
                  " role \"#{suitable_member.state}\"."
                )
                return suitable_member
              end
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
              read_only_states = %i(ReadOnlyReplica PreReadOnlyReplica ReadOnlyLeaderless)
              read_only_states + (ALLOWED_NODE_STATES - read_only_states)
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
      end
    end
  end
end
