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
            headers = { 'Accept' => 'application/vnd.eventstore.atom+json' }
            headers['ES-ResolveLinkTos'] = true if options.key?(:resolve_links)

            response =
              connection.call(
                :get,
                "/streams/#{stream_name}/#{start}/#{direction}/#{count}",
                headers: headers
              )

            return Failure(:stream_not_found) unless response.success? || response.status == 404
            return Failure(:connection_failed) if response.body.nil? || response.body.empty?
            skip_decryption = options[:skip_decryption] || false
            entries = JSON.parse(response.body)['entries'].map do |entry|
              deserialize_event(entry, skip_decryption: skip_decryption)
            end.reverse
            Success(entries)
          rescue Faraday::ConnectionFailed
            Failure(:connection_failed)
          end

          private

          def deserialize_event(entry, skip_decryption: false)
            event = EventStoreClient::Event.new(
              id: entry['eventId'],
              title: entry['title'],
              type: entry['eventType'],
              data: entry['data'] || '{}',
              metadata: entry['isMetaData'] ? entry['metaData'] : '{}'
            )

            config.mapper.deserialize(event, skip_decryption: skip_decryption)
          end
        end
      end
    end
  end
end
