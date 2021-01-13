# frozen_string_literal: true

require 'grpc'
require "base64"

module EventStoreClient
  module GRPC
    class Connection
      include Configuration

      # Initializes the proper stub with the necessary credentials
      # to create working gRPC connection - Refer to generated grpc files
      # @return [Stub] Instance of a given `Stub` klass
      #
      def call(stub_klass, options: {})
        credentials =
          options[:credentials] ||
            Base64.encode64("#{config.eventstore_user}:#{config.eventstore_password}")

        stub_klass.new(
          config.eventstore_url.to_s,
          :this_channel_is_insecure,
          channel_args: { 'authorization' => "Basic #{credentials}"   }
        )
      end
    end
  end
end
