# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: persistent.proto

require 'google/protobuf'
require 'event_store_client/adapters/grpc/generated/shared_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("persistent.proto", :syntax => :proto3) do
    # Read persistent Subscription request
    #
    add_message "event_store.client.persistent_subscriptions.ReadReq" do
      oneof :content do
        optional :options, :message, 1, "event_store.client.persistent_subscriptions.ReadReq.Options"
        optional :ack, :message, 2, "event_store.client.persistent_subscriptions.ReadReq.Ack"
        optional :nack, :message, 3, "event_store.client.persistent_subscriptions.ReadReq.Nack"
      end
    end
    add_message "event_store.client.persistent_subscriptions.ReadReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      optional :group_name, :string, 2
      optional :buffer_size, :int32, 3
      optional :uuid_option, :message, 4, "event_store.client.persistent_subscriptions.ReadReq.Options.UUIDOption"
    end
    add_message "event_store.client.persistent_subscriptions.ReadReq.Options.UUIDOption" do
      oneof :content do
        optional :structured, :message, 1, "event_store.client.shared.Empty"
        optional :string, :message, 2, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.persistent_subscriptions.ReadReq.Ack" do
      optional :id, :bytes, 1
      repeated :ids, :message, 2, "event_store.client.shared.UUID"
    end
    add_message "event_store.client.persistent_subscriptions.ReadReq.Nack" do
      optional :id, :bytes, 1
      repeated :ids, :message, 2, "event_store.client.shared.UUID"
      optional :action, :enum, 3, "event_store.client.persistent_subscriptions.ReadReq.Nack.Action"
      optional :reason, :string, 4
    end
    add_enum "event_store.client.persistent_subscriptions.ReadReq.Nack.Action" do
      value :Unknown, 0
      value :Park, 1
      value :Retry, 2
      value :Skip, 3
      value :Stop, 4
    end

    # Read persistent Subscription response
    #
    add_message "event_store.client.persistent_subscriptions.ReadResp" do
      oneof :content do
        optional :event, :message, 1, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent"
        optional :subscription_confirmation, :message, 2, "event_store.client.persistent_subscriptions.ReadResp.SubscriptionConfirmation"
      end
    end
    add_message "event_store.client.persistent_subscriptions.ReadResp.ReadEvent" do
      optional :event, :message, 1, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent"
      optional :link, :message, 2, "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent"
      oneof :position do
        optional :commit_position, :uint64, 3
        optional :no_position, :message, 4, "event_store.client.shared.Empty"
      end
      oneof :count do
        optional :retry_count, :int32, 5
        optional :no_retry_count, :message, 6, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent" do
      optional :id, :message, 1, "event_store.client.shared.UUID"
      optional :stream_identifier, :message, 2, "event_store.client.shared.StreamIdentifier"
      optional :stream_revision, :uint64, 3
      optional :prepare_position, :uint64, 4
      optional :commit_position, :uint64, 5
      map :metadata, :string, :string, 6
      optional :custom_metadata, :bytes, 7
      optional :data, :bytes, 8
    end
    add_message "event_store.client.persistent_subscriptions.ReadResp.SubscriptionConfirmation" do
      optional :subscription_id, :string, 1
    end

    # Create persistent Subscription request
    #
    add_message "event_store.client.persistent_subscriptions.CreateReq" do
      optional :options, :message, 1, "event_store.client.persistent_subscriptions.CreateReq.Options"
    end
    add_message "event_store.client.persistent_subscriptions.CreateReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      optional :group_name, :string, 2
      optional :settings, :message, 3, "event_store.client.persistent_subscriptions.CreateReq.Settings"
    end
    add_message "event_store.client.persistent_subscriptions.CreateReq.Settings" do
      optional :resolve_links, :bool, 1
      optional :revision, :uint64, 2
      optional :extra_statistics, :bool, 3
      optional :max_retry_count, :int32, 5
      optional :min_checkpoint_count, :int32, 7
      optional :max_checkpoint_count, :int32, 8
      optional :max_subscriber_count, :int32, 9
      optional :live_buffer_size, :int32, 10
      optional :read_batch_size, :int32, 11
      optional :history_buffer_size, :int32, 12
      optional :named_consumer_strategy, :enum, 13, "event_store.client.persistent_subscriptions.CreateReq.ConsumerStrategy"
      oneof :message_timeout do
        optional :message_timeout_ticks, :int64, 4
        optional :message_timeout_ms, :int32, 14
      end
      oneof :checkpoint_after do
        optional :checkpoint_after_ticks, :int64, 6
        optional :checkpoint_after_ms, :int32, 15
      end
    end
    add_enum "event_store.client.persistent_subscriptions.CreateReq.ConsumerStrategy" do
      value :DispatchToSingle, 0
      value :RoundRobin, 1
      value :Pinned, 2
    end

    # Create persistent subscription response
    #
    add_message "event_store.client.persistent_subscriptions.CreateResp" do
    end

    # Update persistent subscription request
    #
    add_message "event_store.client.persistent_subscriptions.UpdateReq" do
      optional :options, :message, 1, "event_store.client.persistent_subscriptions.UpdateReq.Options"
    end
    add_message "event_store.client.persistent_subscriptions.UpdateReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      optional :group_name, :string, 2
      optional :settings, :message, 3, "event_store.client.persistent_subscriptions.UpdateReq.Settings"
    end
    add_message "event_store.client.persistent_subscriptions.UpdateReq.Settings" do
      optional :resolve_links, :bool, 1
      optional :revision, :uint64, 2
      optional :extra_statistics, :bool, 3
      optional :max_retry_count, :int32, 5
      optional :min_checkpoint_count, :int32, 7
      optional :max_checkpoint_count, :int32, 8
      optional :max_subscriber_count, :int32, 9
      optional :live_buffer_size, :int32, 10
      optional :read_batch_size, :int32, 11
      optional :history_buffer_size, :int32, 12
      optional :named_consumer_strategy, :enum, 13, "event_store.client.persistent_subscriptions.UpdateReq.ConsumerStrategy"
      oneof :message_timeout do
        optional :message_timeout_ticks, :int64, 4
        optional :message_timeout_ms, :int32, 14
      end
      oneof :checkpoint_after do
        optional :checkpoint_after_ticks, :int64, 6
        optional :checkpoint_after_ms, :int32, 15
      end
    end
    add_enum "event_store.client.persistent_subscriptions.UpdateReq.ConsumerStrategy" do
      value :DispatchToSingle, 0
      value :RoundRobin, 1
      value :Pinned, 2
    end

    # Update persistent subscription response
    #
    add_message "event_store.client.persistent_subscriptions.UpdateResp" do
    end

    # Delete persistent subscription request
    #
    add_message "event_store.client.persistent_subscriptions.DeleteReq" do
      optional :options, :message, 1, "event_store.client.persistent_subscriptions.DeleteReq.Options"
    end
    add_message "event_store.client.persistent_subscriptions.DeleteReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      optional :group_name, :string, 2
    end

    # Delete persistent subscription response
    #
    add_message "event_store.client.persistent_subscriptions.DeleteResp" do
    end
  end
end

module EventStore
  module Client
    module PersistentSubscriptions
      ReadReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq").msgclass
      ReadReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq.Options").msgclass
      ReadReq::Options::UUIDOption = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq.Options.UUIDOption").msgclass
      ReadReq::Ack = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq.Ack").msgclass
      ReadReq::Nack = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq.Nack").msgclass
      ReadReq::Nack::Action = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadReq.Nack.Action").enummodule
      ReadResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadResp").msgclass
      ReadResp::ReadEvent = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadResp.ReadEvent").msgclass
      ReadResp::ReadEvent::RecordedEvent = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadResp.ReadEvent.RecordedEvent").msgclass
      ReadResp::SubscriptionConfirmation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.ReadResp.SubscriptionConfirmation").msgclass
      CreateReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.CreateReq").msgclass
      CreateReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.CreateReq.Options").msgclass
      CreateReq::Settings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.CreateReq.Settings").msgclass
      CreateReq::ConsumerStrategy = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.CreateReq.ConsumerStrategy").enummodule
      CreateResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.CreateResp").msgclass
      UpdateReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.UpdateReq").msgclass
      UpdateReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.UpdateReq.Options").msgclass
      UpdateReq::Settings = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.UpdateReq.Settings").msgclass
      UpdateReq::ConsumerStrategy = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.UpdateReq.ConsumerStrategy").enummodule
      UpdateResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.UpdateResp").msgclass
      DeleteReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.DeleteReq").msgclass
      DeleteReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.DeleteReq.Options").msgclass
      DeleteResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.persistent_subscriptions.DeleteResp").msgclass
    end
  end
end
