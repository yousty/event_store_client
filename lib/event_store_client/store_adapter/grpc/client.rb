# frozen_string_literal: true

require 'grpc'
require 'event_store_client/value_objects/read_direction.rb'
require 'event_store_client/store_adapter/grpc/generated/shared_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/streams/append'
require 'event_store_client/store_adapter/grpc/commands/streams/delete'
require 'event_store_client/store_adapter/grpc/commands/streams/read'
require 'event_store_client/store_adapter/grpc/commands/streams/read_all'
require 'event_store_client/store_adapter/grpc/commands/streams/tombstone'

require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/create'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/update'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/delete'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/read'

require 'event_store_client/store_adapter/grpc/commands/projections/create'
require 'event_store_client/store_adapter/grpc/commands/projections/update'
require 'event_store_client/store_adapter/grpc/commands/projections/delete'


module EventStoreClient
  module StoreAdapter
    module GRPC
      class Client
        WrongExpectedEventVersion = Class.new(StandardError)

        def append_to_stream(stream_name, events, expected_version: nil)
          Commands::Streams::Append.new.call(stream_name, events, expected_version: expected_version)
        end

        def delete_stream(stream_name, tombstone: false, options: {})
          return Commands::Streams::Tombstone.new.call(stream_name, options: options) if tombstone

          Commands::Streams::Delete.new.call(stream_name, options: options)
        end

        def read(stream_name, direction: 'forwards', start: 0, count: nil, resolve_links: true)
          Commands::Streams::Read.new.call(
            stream_name,
            options: {
              start: start, direction: direction, count: count, resolve_links: resolve_links
            }
          )
        end

        def read_all_from_stream(stream, start: 0, resolve_links: true)
          # Commands::Streams::ReadAll.new.call(stream_name, options: options)
          count = per_page
          start ||= 0
          events = []

          loop do
            entries = read(
              stream,
              options: {
                start: start, direction: direction, count: count, resolve_links: resolve_links
              }
            )
            break if entries.empty?
            events += entries
            start += count
          end

          events
        end

        def join_streams(name, streams)
          Commands::Projections::Create.new.call(name, streams)
          Commands::Projections::Update.new.call(name, streams)
        end

        def subscribe_to_stream(stream_name, subscription_name, stats: true, start_from: 0, retries: 5)
          Commands::PersistentSubscriptions::Create.new.call(
            stream_name,
            subscription_name,
            options: {}
          )
        end

        private

        attr_reader :uri, :per_page, :connection_options, :mapper

        def initialize(uri, mapper:, per_page: 20, connection_options: {})
          @uri = uri
          @per_page = per_page
          @mapper = mapper
          @connection_options = connection_options
        end

        def build_linkig_data(events)
          [events].flatten.map do |event|
            {
              eventId: event.id,
              eventType: '$>',
              data: event.title,
            }
          end
        end

        def connection
          EventStoreClient::StoreAdapter::GRPC::Connection.new(uri).call
        end
      end
    end
  end
end
