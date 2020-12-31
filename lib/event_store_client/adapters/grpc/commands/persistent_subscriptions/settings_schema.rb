# frozen_string_literal: true

require 'grpc'
require 'event_store_client/adapters/grpc/generated/persistent_pb.rb'
require 'event_store_client/adapters/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/command'

module EventStoreClient
  module GRPC
    module Commands
      module PersistentSubscriptions
        # Ensures the proper format of the parameters passed to the subscirption request
        #
        SettingsSchema = Dry::Schema.Params do
          optional(:resolve_links).value(Dry::Types['bool'].default(true))
          optional(:revision).value(Dry::Types['integer'])
          optional(:extra_statistics).value(Dry::Types['bool'])
          optional(:max_retry_count).value(Dry::Types['integer'])
          optional(:min_checkpoint_count).value(Dry::Types['integer'])
          optional(:max_checkpoint_count).value(Dry::Types['integer'])
          optional(:max_subscriber_count).value(Dry::Types['integer'])
          optional(:live_buffer_size).value(Dry::Types['integer'])
          optional(:read_batch_size).value(Dry::Types['integer'])
          optional(:history_buffer_size).value(Dry::Types['integer'].default(500))
          optional(:message_timeout_ms).value(Dry::Types['integer'].default(10_000))
          # optional(:message_timeout_ticks).value(Dry::Types['integer'].default(10000))

          optional(:checkpoint_after_ms).value(Dry::Types['integer'].default(1000))
          optional(:named_consumer_strategy).value(
            Dry::Types['symbol'].default(:RoundRobin),
            included_in?: %i[DispatchToSingle RoundRobin Pinned]
          )
        end
      end
    end
  end
end
