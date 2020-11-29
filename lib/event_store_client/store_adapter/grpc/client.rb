# frozen_string_literal: true

require 'grpc'
require 'event_store_client/value_objects/read_direction.rb'
require 'event_store_client/store_adapter/grpc/generated/shared_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_pb.rb'
require 'event_store_client/store_adapter/grpc/generated/streams_services_pb.rb'
# require 'event_store_client/store_adapter/grpc/connection'

module EventStoreClient
  module StoreAdapter
    module GRPC
      class Client
        WrongExpectedEventVersion = Class.new(StandardError)

        def read(stream_name, direction: 'forwards', count: nil, start: 0, resolve_links: true)
          options = {
            stream: {
              stream_identifier: {
                streamName: stream_name
              }
            },
            read_direction: EventStoreClient::ReadDirection.new(direction).to_sym,
            resolve_links: resolve_links,
            count: count || per_page,
            uuid_option: {
              string: {}
            },
            no_filter: {}
          }
          start.zero? ? (options[:stream][:start] = {}) : (options[:stream][:revision] = start)

          client = EventStore::Client::Streams::Streams::Stub.new(
            uri.to_s, :this_channel_is_insecure
          )

          request = ::EventStore::Client::Streams::ReadReq.new(options: options)

          client.read(request).map do |res|
            deserialize_event(res.event.event)
          end
        end

        def read_all_from_stream(stream, direction: 'forwards', per_page: 20, start: 0, resolve_links: true)
          events = []
          while (entries = read(stream, start: start, direction: direction, count: per_page, resolve_links: resolve_links)).any?
            events += entries
            start += per_page
          end
          events
        end

        private

        attr_reader :uri, :per_page, :connection_options, :mapper

        def initialize(uri, mapper:, per_page: 20, connection_options: {})
          @uri = uri
          @per_page = per_page
          @mapper = mapper
          @connection_options = connection_options
        end

        def build_events_data(events)
          [events].flatten.map do |event|
            {
              eventId: event.id,
              eventType: event.type,
              data: event.data,
              metadata: event.metadata
            }
          end
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

        def deserialize_event(entry)
          event = EventStoreClient::Event.new(
            id: entry.id.string,
            title: "#{entry.stream_revision}@#{entry.stream_identifier.streamName}",
            type: entry.metadata['type'],
            data: entry.data || '{}',
            metadata: (entry.metadata.to_h || {}).to_json
          )

          mapper.deserialize(event)
        end
      end
    end
  end
end
