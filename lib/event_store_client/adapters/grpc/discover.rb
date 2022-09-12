# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity

module EventStoreClient
  module GRPC
    class Discover
      include Configuration

      class << self
        # @return [EventStoreClient::GRPC::Cluster::Member]
        def current_member
          @exception = nil
          return @current_member if member_alive?

          semaphore.synchronize do
            raise @exception if @exception
            return @current_member if member_alive?

            failed_member = @current_member if @current_member&.failed_endpoint
            @current_member =
              begin
                new.call(failed_member: failed_member)
              rescue StandardError => e
                @exception = e
                nil
              end
          end
          raise @exception if @exception

          @current_member
        end

        # @return [Boolean]
        def member_alive?
          return false if @current_member&.failed_endpoint

          !@current_member.nil?
        end

        private

        # @return [Thread::Mutex]
        def semaphore
          @semaphore ||= Thread::Mutex.new
        end
      end

      # @param failed_member [EventStoreClient::GRPC::Cluster::Member, nil]
      # @return [EventStoreClient::GRPC::Cluster::Member]
      def call(failed_member: nil)
        if needs_discover?
          return Cluster::GossipDiscover.new.call(nodes, failed_member: failed_member)
        end

        Cluster::QuerylessDiscover.new.call(config.eventstore_url.nodes.to_a)
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
