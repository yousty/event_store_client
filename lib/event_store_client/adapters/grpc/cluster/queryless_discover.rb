# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Cluster
      class QuerylessDiscover
        NoHostError = Class.new(StandardError)

        attr_reader :config
        private :config

        # @param config [EventStoreClient::Config]
        def initialize(config:)
          @config = config
        end

        # @param nodes [EventStoreClient::Connection::Url::Node]
        # @return [EventStoreClient::GRPC::Cluster::Member]
        def call(nodes)
          raise NoHostError, 'No host setup' if nodes.empty?

          Member.new(host: nodes.first.host, port: nodes.first.port).tap do |member|
            config.logger&.debug(
              "Picking #{member.host}:#{member.port} member without cluster discovery."
            )
          end
        end
      end
    end
  end
end
