# frozen_string_literal: true

module EventStoreClient
  module HTTP
    module Commands
      module Streams
        class LinkTo < Command
          def call(stream_name, events, options: {})
            expected_version = options[:expected_version]
            data = build_linking_data(events)
            headers = {
              'ES-ExpectedVersion' => expected_version&.to_s
            }.reject { |_key, val| val.nil? || val.empty? }

            response = connection.call(
              :post,
              "/streams/#{stream_name}",
              body: data,
              headers: headers
            )
            validate_response(response, expected_version)
          end

          private

          def validate_response(resp, expected_version)
            wrong_version = resp.status == 400 && resp.reason_phrase == 'Wrong expected EventNumber'
            return Success() unless wrong_version

            Failure(
              "current version: #{resp.headers.fetch('es-currentversion')} | "\
              "expected: #{expected_version}"
            )
          end

          def build_linking_data(events)
            [events].flatten.map do |event|
              {
                eventId: event.id,
                eventType: '$>',
                data: event.title
              }
            end
          end
        end
      end
    end
  end
end
