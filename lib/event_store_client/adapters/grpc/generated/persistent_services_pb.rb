# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: persistent.proto for package 'event_store.client.persistent_subscriptions'

require 'grpc'

require 'event_store_client/adapters/grpc/generated/persistent_pb'

module EventStore
  module Client
    module PersistentSubscriptions
      module PersistentSubscriptions
        class Service
          include GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'event_store.client.persistent_subscriptions.PersistentSubscriptions'

          rpc :Create, ::EventStore::Client::PersistentSubscriptions::CreateReq, ::EventStore::Client::PersistentSubscriptions::CreateResp
          rpc :Update, ::EventStore::Client::PersistentSubscriptions::UpdateReq, ::EventStore::Client::PersistentSubscriptions::UpdateResp
          rpc :Delete, ::EventStore::Client::PersistentSubscriptions::DeleteReq, ::EventStore::Client::PersistentSubscriptions::DeleteResp
          rpc :Read, stream(::EventStore::Client::PersistentSubscriptions::ReadReq), stream(::EventStore::Client::PersistentSubscriptions::ReadResp)
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
