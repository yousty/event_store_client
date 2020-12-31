# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Streams
        class Append < Command
          include Configuration

          def call(stream_name, events, expected_version:)
            serialized_events = events.map { |event| config.mapper.serialize(event) }
            headers = {
              'ES-ExpectedVersion' => expected_version&.to_s
            }.reject { |_key, val| val.nil? || val.empty? }

            data = build_events_data(serialized_events)
            response =
              connection.call(:post, "/streams/#{stream_name}", body: data, headers: headers)
            validate_response(response, expected_version)
          end

          private

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

          def validate_response(resp, expected_version)
            wrong_version = resp.status == 400 && resp.reason_phrase == 'Wrong expected EventNumber'
            return Success() unless wrong_version

            Failure(
              "current version: #{resp.headers.fetch('es-currentversion')} | "\
              "expected: #{expected_version}"
            )
          end
        end
      end
    end
  end
end
