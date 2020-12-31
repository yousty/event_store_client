# frozen_string_literal: true

require 'event_store_client/adapters/http/commands/persistent_subscriptions/ack'
module EventStoreClient
  module HTTP
    module Commands
      module PersistentSubscriptions
        class Read < Command
          include Configuration

          def call(stream_name, subscription_name, options: {})
            count = options[:count] || 20
            long_poll = options[:long_poll].to_i
            headers = long_poll.positive? ? { 'ES-LongPoll' => long_poll.to_s } : {}
            headers['Content-Type'] = 'application/vnd.eventstore.competingatom+json'
            headers['Accept'] = 'application/vnd.eventstore.competingatom+json'
            headers['ES-ResolveLinktos'] = (options[:resolve_links] || true).to_s

            response = connection.call(
              :get,
              "/subscriptions/#{stream_name}/#{subscription_name}/#{count}",
              headers: headers
            )

            return { events: [] } if response.body.nil? || response.body.empty?

            body = JSON.parse(response.body)

            ack_info = body['links'].find { |link| link['relation'] == 'ackAll' }
            return { events: [] } unless ack_info
            body['entries'].map do |entry|
              yield deserialize_event(entry)
            end
            Ack.new(connection).call(ack_info['uri'])
            Success()
          end

          private

          def deserialize_event(entry)
            event = EventStoreClient::Event.new(
              id: entry['eventId'],
              title: entry['title'],
              type: entry['eventType'],
              data: entry['data'] || '{}',
              metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
            )

            config.mapper.deserialize(event)
          rescue EventStoreClient::DeserializedEvent::InvalidDataError
            event
          end
        end
      end
    end
  end
end
