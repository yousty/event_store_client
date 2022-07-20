# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class LinkTo < Command
          # @see {EventStoreClient::GRPC::Client#hard_delete_stream}
          def call(stream_name, event, options:, &blk)
            append_cmd = Append.new(username: username, password: username)
            link_event = EventStoreClient::DeserializedEvent.new(
              id: event.id, type: '$>', data: event.title
            )
            append_cmd.call(stream_name, link_event, options: options, &blk)
          end
        end
      end
    end
  end
end
