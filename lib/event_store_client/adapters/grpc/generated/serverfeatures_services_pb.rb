# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: serverfeatures.proto for package 'event_store.client.server_features'

require 'grpc'
require_relative 'serverfeatures_pb'

module EventStore
  module Client
    module ServerFeatures
      module ServerFeatures
        class Service

          include ::GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'event_store.client.server_features.ServerFeatures'

          rpc :GetSupportedMethods, ::EventStore::Client::Empty, ::EventStore::Client::ServerFeatures::SupportedMethods
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
