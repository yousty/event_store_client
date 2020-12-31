# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Streams
        class Read < Command
          include Configuration

          def call(stream_name, options: {})
            count = options[:count] || config.per_page
            start = options[:start].to_i
            direction = options[:direction] || 'forward'
            headers = {
              'ES-ResolveLinkTos' => options[:resolve_links].to_s,
              'Accept' => 'application/vnd.eventstore.atom+json'
            }

            response =
              connection.call(
                :get,
                "/streams/#{stream_name}/#{start}/#{direction}/#{count}",
                headers: headers
              )

            return Failure(:stream_not_found) unless response.success? || response.status == 404
            return Failure(:connection_failed) if response.body.nil? || response.body.empty?
            entries = JSON.parse(response.body)['entries'].map do |entry|
              deserialize_event(entry)
            end.reverse
            Success(entries)
          rescue Faraday::ConnectionFailed
            Failure(:connection_failed)
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
          end
        end
      end
    end
  end
end
