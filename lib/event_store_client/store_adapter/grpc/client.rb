# frozen_string_literal: true

require 'grpc'
require 'event_store_client/value_objects/read_direction.rb'
require 'event_store_client/store_adapter/grpc/generated/shared_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/streams/delete'
require 'event_store_client/store_adapter/grpc/commands/streams/read'
require 'event_store_client/store_adapter/grpc/commands/streams/tombstone'

require 'event_store_client/store_adapter/grpc/generated/persistent_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/create'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/update'
require 'event_store_client/store_adapter/grpc/commands/persistent_subscriptions/delete'

require 'event_store_client/store_adapter/grpc/commands/projections/create'
require 'event_store_client/store_adapter/grpc/commands/projections/update'
require 'event_store_client/store_adapter/grpc/commands/projections/delete'
# require 'event_store_client/store_adapter/grpc/connection'

module EventStoreClient
  module StoreAdapter
    module GRPC
      class Client
        WrongExpectedEventVersion = Class.new(StandardError)
        StreamNotFound = Class.new(StandardError)

        def append_to_stream(stream_name, events, expected_version: nil)
          Commands::Streams::Append.new.call(stream_name, events, expected_version: expected_version)
        end

        def delete_stream(stream_name, tombstone: false, options: {})
          return Commands::Streams::Tombstone.new.call(stream_name, options: options) if tombstone

          Commands::Streams::Delete.new.call(stream_name, options: options)
        end

        def read(stream_name, options: {})
          Commands::Streams::Read.new.call(stream_name, options: options)
        end

        def read_all_from_stream(stream, options: {})
          events = []
          while (entries = read(stream, options: options)).any?
            events += entries
            start += per_page
          end
          events
        end

        def join_streams(name, streams)
          Commands::Projections::Create.new.call(name, streams)
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

        def make_request(method_name, path, body: {}, headers: {})
          method = RequestMethod.new(method_name)
          connection.send(method.to_s, path) do |req|
            req.headers = req.headers.merge(headers)
            req.body = body.is_a?(String) ? body : body.to_json
            req.params['embed'] = 'body' if method == :get
          end
        end

        def connection
          EventStoreClient::StoreAdapter::GRPC::Connection.new(uri).call
        end

        def validate_response(resp, expected_version)
          return unless resp.status == 400 && resp.reason_phrase == 'Wrong expected EventNumber'
          raise WrongExpectedEventVersion.new(
            "current version: #{resp.headers.fetch('es-currentversion')} | "\
            "expected: #{expected_version}"
          )
        end
      end
    end
  end
end
