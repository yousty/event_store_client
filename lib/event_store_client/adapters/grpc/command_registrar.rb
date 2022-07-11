# frozen_string_literal: true

require 'event_store_client/adapters/grpc/connection'

module EventStoreClient
  module GRPC
    class CommandRegistrar
      @commands = {}

      def self.register_request(command_klass, request:)
        @commands[command_klass] ||= {}
        @commands[command_klass][:request] = request
      end

      def self.register_service(command_klass, service:)
        @commands[command_klass] ||= {}
        @commands[command_klass][:service] = service
      end

      def self.request(command_klass)
        @commands[command_klass][:request]
      end

      # @param command_klass [Class] GRPC service class.
      #   Examples:
      #     - EventStore::Client::Streams::Streams::Stub
      #     - EventStore::Client::Projections::Projections::Stub
      #
      # @return [Object] and instance of GRPC service class you have provided
      def self.service(command_klass, options: {})
        EventStoreClient::GRPC::Connection.new.call(
          @commands[command_klass][:service], options: options
        )
      end
    end
  end
end
