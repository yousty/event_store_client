# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: operations.proto for package 'event_store.client.operations'

require 'grpc'
require_relative 'operations_pb'

module EventStore
  module Client
    module Operations
      module Operations
        class Service

          include ::GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'event_store.client.operations.Operations'

          rpc :StartScavenge, ::EventStore::Client::Operations::StartScavengeReq, ::EventStore::Client::Operations::ScavengeResp
          rpc :StopScavenge, ::EventStore::Client::Operations::StopScavengeReq, ::EventStore::Client::Operations::ScavengeResp
          rpc :Shutdown, ::EventStore::Client::Empty, ::EventStore::Client::Empty
          rpc :MergeIndexes, ::EventStore::Client::Empty, ::EventStore::Client::Empty
          rpc :ResignNode, ::EventStore::Client::Empty, ::EventStore::Client::Empty
          rpc :SetNodePriority, ::EventStore::Client::Operations::SetNodePriorityReq, ::EventStore::Client::Empty
          rpc :RestartPersistentSubscriptions, ::EventStore::Client::Empty, ::EventStore::Client::Empty
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
