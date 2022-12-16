# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity

module EventStoreClient
  module GRPC
    class Discover
      @exception = {}
      @current_member = {}

      class << self
        # @param config [EventStoreClient::Config]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        def current_member(config:)
          @exception[config.name] = nil
          return @current_member[config.name] if member_alive?(@current_member[config.name])

          semaphore.synchronize do
            raise @exception[config.name] if @exception[config.name]
            return @current_member[config.name] if member_alive?(@current_member[config.name])

            failed_member =
              if @current_member[config.name]&.failed_endpoint
                @current_member[config.name]
              end

            @current_member[config.name] =
              begin
                new(config: config).call(failed_member: failed_member)
              rescue StandardError => e
                @exception[config.name] = e
                nil
              end
          end
          raise @exception[config.name] if @exception[config.name]

          @current_member[config.name]
        end

        # @param member [EventStoreClient::GRPC::Cluster::Member, nil]
        # @return [Boolean]
        def member_alive?(member)
          return false if member&.failed_endpoint

          !member.nil?
        end

        private

        # @return [Thread::Mutex]
        def semaphore
          @semaphore ||= Thread::Mutex.new
        end
      end

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
