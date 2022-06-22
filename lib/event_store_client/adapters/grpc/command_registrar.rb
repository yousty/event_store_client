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

      def self.service(command_klass)
        EventStoreClient::GRPC::Connection.new.call(
          @commands[command_klass][:service]
        )
      end
    end
  end
end
