# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity

module EventStoreClient
  module GRPC
    class Discover
      class << self
        # @param config [EventStoreClient::Config]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        def current_member(config:)
          @exception[config.name] = nil
          return @current_member[config.name] if member_alive?(@current_member[config.name])

          semaphore(config.name).synchronize do
            current_member = @current_member[config.name]
            raise @exception[config.name] if @exception[config.name]
            return current_member if member_alive?(current_member)

            failed_member = current_member&.failed_endpoint ? current_member : nil
            begin
              @current_member[config.name] = new(config: config).call(failed_member: failed_member)
            rescue StandardError => e
              @exception[config.name] = e
              @current_member[config.name] = nil
              raise
            end
          end

          @current_member[config.name]
        end

        # @param member [EventStoreClient::GRPC::Cluster::Member, nil]
        # @return [Boolean]
        def member_alive?(member)
          return false if member&.failed_endpoint

          !member.nil?
        end

        # @return [void]
        def init_default_discover_vars
          @exception = {}
          @current_member = {}
          @semaphore = {}
        end

        private

        # @param config_name [String, Symbol]
        # @return [Thread::Mutex]
        def semaphore(config_name)
          @semaphore[config_name] ||= Thread::Mutex.new
        end
      end

      init_default_discover_vars

      attr_reader :config
      private :config

      # @param config [EventStoreClient::Config]
      def initialize(config:)
        @config = config
      end

      # @param failed_member [EventStoreClient::GRPC::Cluster::Member, nil]
      # @return [EventStoreClient::GRPC::Cluster::Member]
      def call(failed_member: nil)
        if needs_discover?
          discovery =
            Cluster::GossipDiscover.new(config: config).call(nodes, failed_member: failed_member)
          return discovery
        end

        Cluster::QuerylessDiscover.new(config: config).call(config.eventstore_url.nodes.to_a)
      end

      private

      # @return [Array<EventStoreClient::Connection::Url::Node>]
      def nodes
        return [config.eventstore_url.nodes.first] if config.eventstore_url.dns_discover

        config.eventstore_url.nodes.to_a
      end

      # @return [Boolean]
      def needs_discover?
        config.eventstore_url.dns_discover || config.eventstore_url.nodes.size > 1
      end
    end
  end
end
# rubocop:enable Metrics/CyclomaticComplexity
