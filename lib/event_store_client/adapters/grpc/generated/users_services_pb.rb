# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: users.proto for package 'event_store.client.users'

require 'grpc'
require_relative 'users_pb'

module EventStore
  module Client
    module Users
      module Users
        class Service

          include ::GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'event_store.client.users.Users'

          rpc :Create, ::EventStore::Client::Users::CreateReq, ::EventStore::Client::Users::CreateResp
          rpc :Update, ::EventStore::Client::Users::UpdateReq, ::EventStore::Client::Users::UpdateResp
          rpc :Delete, ::EventStore::Client::Users::DeleteReq, ::EventStore::Client::Users::DeleteResp
          rpc :Disable, ::EventStore::Client::Users::DisableReq, ::EventStore::Client::Users::DisableResp
          rpc :Enable, ::EventStore::Client::Users::EnableReq, ::EventStore::Client::Users::EnableResp
          rpc :Details, ::EventStore::Client::Users::DetailsReq, stream(::EventStore::Client::Users::DetailsResp)
          rpc :ChangePassword, ::EventStore::Client::Users::ChangePasswordReq, ::EventStore::Client::Users::ChangePasswordResp
          rpc :ResetPassword, ::EventStore::Client::Users::ResetPasswordReq, ::EventStore::Client::Users::ResetPasswordResp
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
