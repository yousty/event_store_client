# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: streams.proto

require 'google/protobuf'

require 'event_store_client/store_adapter/grpc/generated/shared_pb'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("streams.proto", :syntax => :proto3) do
    ### Read Request definition
    #
    add_message "event_store.client.streams.ReadReq" do
      optional :options, :message, 1, "event_store.client.streams.ReadReq.Options"
    end
    add_message "event_store.client.streams.ReadReq.Options" do
      optional :read_direction, :enum, 3, "event_store.client.streams.ReadReq.Options.ReadDirection"
      optional :resolve_links, :bool, 4
      optional :uuid_option, :message, 9, "event_store.client.streams.ReadReq.Options.UUIDOption"
      oneof :stream_option do
        optional :stream, :message, 1, "event_store.client.streams.ReadReq.Options.StreamOptions"
        optional :all, :message, 2, "event_store.client.streams.ReadReq.Options.AllOptions"
      end
      oneof :count_option do
        optional :count, :uint64, 5
        optional :subscription, :message, 6, "event_store.client.streams.ReadReq.Options.SubscriptionOptions"
      end
      oneof :filter_option do
        optional :filter, :message, 7, "event_store.client.streams.ReadReq.Options.FilterOptions"
        optional :no_filter, :message, 8, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.ReadReq.Options.StreamOptions" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      oneof :revision_option do
        optional :revision, :uint64, 2
        optional :start, :message, 3, "event_store.client.shared.Empty"
        optional :end, :message, 4, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.ReadReq.Options.AllOptions" do
      oneof :all_option do
        optional :position, :message, 1, "event_store.client.streams.ReadReq.Options.Position"
        optional :start, :message, 2, "event_store.client.shared.Empty"
        optional :end, :message, 3, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.ReadReq.Options.SubscriptionOptions" do
    end
    add_message "event_store.client.streams.ReadReq.Options.Position" do
      optional :commit_position, :uint64, 1
      optional :prepare_position, :uint64, 2
    end
    add_message "event_store.client.streams.ReadReq.Options.FilterOptions" do
      optional :checkpointIntervalMultiplier, :uint32, 5
      oneof :filter do
        optional :stream_identifier, :message, 1, "event_store.client.streams.ReadReq.Options.FilterOptions.Expression"
        optional :event_type, :message, 2, "event_store.client.streams.ReadReq.Options.FilterOptions.Expression"
      end
      oneof :window do
        optional :max, :uint32, 3
        optional :count, :message, 4, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.ReadReq.Options.FilterOptions.Expression" do
      optional :regex, :string, 1
      repeated :prefix, :string, 2
    end
    add_message "event_store.client.streams.ReadReq.Options.UUIDOption" do
      oneof :content do
        optional :structured, :message, 1, "event_store.client.shared.Empty"
        optional :string, :message, 2, "event_store.client.shared.Empty"
      end
    end
    add_enum "event_store.client.streams.ReadReq.Options.ReadDirection" do
      value :Forwards, 0
      value :Backwards, 1
    end

    # Read Response definition
    #
    add_message "event_store.client.streams.ReadResp" do
      oneof :content do
        optional :event, :message, 1, "event_store.client.streams.ReadResp.ReadEvent"
        optional :confirmation, :message, 2, "event_store.client.streams.ReadResp.SubscriptionConfirmation"
        optional :checkpoint, :message, 3, "event_store.client.streams.ReadResp.Checkpoint"
        optional :stream_not_found, :message, 4, "event_store.client.streams.ReadResp.StreamNotFound"
      end
    end
    add_message "event_store.client.streams.ReadResp.ReadEvent" do
      optional :event, :message, 1, "event_store.client.streams.ReadResp.ReadEvent.RecordedEvent"
      optional :link, :message, 2, "event_store.client.streams.ReadResp.ReadEvent.RecordedEvent"
      oneof :position do
        optional :commit_position, :uint64, 3
        optional :no_position, :message, 4, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.ReadResp.ReadEvent.RecordedEvent" do
      optional :id, :message, 1, "event_store.client.shared.UUID"
      optional :stream_identifier, :message, 2, "event_store.client.shared.StreamIdentifier"
      optional :stream_revision, :uint64, 3
      optional :prepare_position, :uint64, 4
      optional :commit_position, :uint64, 5
      map :metadata, :string, :string, 6
      optional :custom_metadata, :bytes, 7
      optional :data, :bytes, 8
    end
    add_message "event_store.client.streams.ReadResp.SubscriptionConfirmation" do
      optional :subscription_id, :string, 1
    end
    add_message "event_store.client.streams.ReadResp.Checkpoint" do
      optional :commit_position, :uint64, 1
      optional :prepare_position, :uint64, 2
    end
    add_message "event_store.client.streams.ReadResp.StreamNotFound" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
    end

    # Append to stream request
    #
    add_message "event_store.client.streams.AppendReq" do
      oneof :content do
        optional :options, :message, 1, "event_store.client.streams.AppendReq.Options"
        optional :proposed_message, :message, 2, "event_store.client.streams.AppendReq.ProposedMessage"
      end
    end
    add_message "event_store.client.streams.AppendReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      oneof :expected_stream_revision do
        optional :revision, :uint64, 2
        optional :no_stream, :message, 3, "event_store.client.shared.Empty"
        optional :any, :message, 4, "event_store.client.shared.Empty"
        optional :stream_exists, :message, 5, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.AppendReq.ProposedMessage" do
      optional :id, :message, 1, "event_store.client.shared.UUID"
      map :metadata, :string, :string, 2
      optional :custom_metadata, :bytes, 3
      optional :data, :bytes, 4
    end

    # Append to stream response
    #
    add_message "event_store.client.streams.AppendResp" do
      oneof :result do
        optional :success, :message, 1, "event_store.client.streams.AppendResp.Success"
        optional :wrong_expected_version, :message, 2, "event_store.client.streams.AppendResp.WrongExpectedVersion"
      end
    end
    add_message "event_store.client.streams.AppendResp.Position" do
      optional :commit_position, :uint64, 1
      optional :prepare_position, :uint64, 2
    end
    add_message "event_store.client.streams.AppendResp.Success" do
      oneof :current_revision_option do
        optional :current_revision, :uint64, 1
        optional :no_stream, :message, 2, "event_store.client.shared.Empty"
      end
      oneof :position_option do
        optional :position, :message, 3, "event_store.client.streams.AppendResp.Position"
        optional :no_position, :message, 4, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.AppendResp.WrongExpectedVersion" do
      oneof :current_revision_option_20_6_0 do
        optional :current_revision_20_6_0, :uint64, 1
        optional :no_stream_20_6_0, :message, 2, "event_store.client.shared.Empty"
      end
      oneof :expected_revision_option_20_6_0 do
        optional :expected_revision_20_6_0, :uint64, 3
        optional :any_20_6_0, :message, 4, "event_store.client.shared.Empty"
        optional :stream_exists_20_6_0, :message, 5, "event_store.client.shared.Empty"
      end
      oneof :current_revision_option do
        optional :current_revision, :uint64, 6
        optional :current_no_stream, :message, 7, "event_store.client.shared.Empty"
      end
      oneof :expected_revision_option do
        optional :expected_revision, :uint64, 8
        optional :expected_any, :message, 9, "event_store.client.shared.Empty"
        optional :expected_stream_exists, :message, 10, "event_store.client.shared.Empty"
        optional :expected_no_stream, :message, 11, "event_store.client.shared.Empty"
      end
    end

    # Delete stream request
    #
    add_message "event_store.client.streams.DeleteReq" do
      optional :options, :message, 1, "event_store.client.streams.DeleteReq.Options"
    end
    add_message "event_store.client.streams.DeleteReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      oneof :expected_stream_revision do
        optional :revision, :uint64, 2
        optional :no_stream, :message, 3, "event_store.client.shared.Empty"
        optional :any, :message, 4, "event_store.client.shared.Empty"
        optional :stream_exists, :message, 5, "event_store.client.shared.Empty"
      end
    end

    # Delete stream response
    #
    add_message "event_store.client.streams.DeleteResp" do
      oneof :position_option do
        optional :position, :message, 1, "event_store.client.streams.DeleteResp.Position"
        optional :no_position, :message, 2, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.DeleteResp.Position" do
      optional :commit_position, :uint64, 1
      optional :prepare_position, :uint64, 2
    end

    # Tombstone stream request
    #
    add_message "event_store.client.streams.TombstoneReq" do
      optional :options, :message, 1, "event_store.client.streams.TombstoneReq.Options"
    end
    add_message "event_store.client.streams.TombstoneReq.Options" do
      optional :stream_identifier, :message, 1, "event_store.client.shared.StreamIdentifier"
      oneof :expected_stream_revision do
        optional :revision, :uint64, 2
        optional :no_stream, :message, 3, "event_store.client.shared.Empty"
        optional :any, :message, 4, "event_store.client.shared.Empty"
        optional :stream_exists, :message, 5, "event_store.client.shared.Empty"
      end
    end

    # Tombstone stream response
    #
    add_message "event_store.client.streams.TombstoneResp" do
      oneof :position_option do
        optional :position, :message, 1, "event_store.client.streams.TombstoneResp.Position"
        optional :no_position, :message, 2, "event_store.client.shared.Empty"
      end
    end
    add_message "event_store.client.streams.TombstoneResp.Position" do
      optional :commit_position, :uint64, 1
      optional :prepare_position, :uint64, 2
    end
  end
end

module EventStore
  module Client
    module Streams
      ReadReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq").msgclass
      ReadReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options").msgclass
      ReadReq::Options::StreamOptions = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.StreamOptions").msgclass
      ReadReq::Options::AllOptions = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.AllOptions").msgclass
      ReadReq::Options::SubscriptionOptions = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.SubscriptionOptions").msgclass
      ReadReq::Options::Position = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.Position").msgclass
      ReadReq::Options::FilterOptions = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.FilterOptions").msgclass
      ReadReq::Options::FilterOptions::Expression = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.FilterOptions.Expression").msgclass
      ReadReq::Options::UUIDOption = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.UUIDOption").msgclass
      ReadReq::Options::ReadDirection = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadReq.Options.ReadDirection").enummodule
      ReadResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp").msgclass
      ReadResp::ReadEvent = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp.ReadEvent").msgclass
      ReadResp::ReadEvent::RecordedEvent = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp.ReadEvent.RecordedEvent").msgclass
      ReadResp::SubscriptionConfirmation = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp.SubscriptionConfirmation").msgclass
      ReadResp::Checkpoint = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp.Checkpoint").msgclass
      ReadResp::StreamNotFound = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.ReadResp.StreamNotFound").msgclass
      AppendReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendReq").msgclass
      AppendReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendReq.Options").msgclass
      AppendReq::ProposedMessage = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendReq.ProposedMessage").msgclass
      AppendResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendResp").msgclass
      AppendResp::Position = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendResp.Position").msgclass
      AppendResp::Success = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendResp.Success").msgclass
      AppendResp::WrongExpectedVersion = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.AppendResp.WrongExpectedVersion").msgclass
      DeleteReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.DeleteReq").msgclass
      DeleteReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.DeleteReq.Options").msgclass
      DeleteResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.DeleteResp").msgclass
      DeleteResp::Position = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.DeleteResp.Position").msgclass
      TombstoneReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.TombstoneReq").msgclass
      TombstoneReq::Options = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.TombstoneReq.Options").msgclass
      TombstoneResp = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.TombstoneResp").msgclass
      TombstoneResp::Position = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("event_store.client.streams.TombstoneResp.Position").msgclass
    end
  end
end