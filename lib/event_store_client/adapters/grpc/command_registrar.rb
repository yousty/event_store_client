# frozen_string_literal: true

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
        @commands.dig(command_klass,:request)
      end

      # @param command_klass [Class]
      #   Examples:
      #     - EventStoreClient::GRPC::Commands::Streams::Append
      #     - EventStoreClient::GRPC::Commands::Streams::Read
      # @return [Object] GRPC service class
      def self.service(command_klass)
        @commands.dig(command_klass,:service)
      end
    end
  end
end
