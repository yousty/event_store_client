# frozen_string_literal: true

# rubocop:disable all

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class ReadPaginated < Command
          RecordsLimitError = Class.new(StandardError)
          DEFAULT_READ_DIRECTION = :Forwards

          # @api private
          # @see {EventStoreClient::GRPC::Client#read_paginated}
          def call(stream_name, options:, skip_deserialization:, skip_decryption:, &blk)
            # TODO: Improve the implementation by extracting the pagination into a separate class to
            # allow persisting the pagination options(position, direction, max_count) among the
            # whole instance. This approach will allow us to get rid of passing paginate options
            # into private methods explicitly.
            position, direction, max_count = nil
            first_call = true
            Enumerator.new do |yielder|
              loop do
                response =
                  Read.new(config: config, **connection_options).call(
                    stream_name,
                    options: options,
                    skip_deserialization: true,
                    skip_decryption: true
                  ) do |opts|
                    if first_call
                      # Evaluate user-provided block only once
                      yield opts if blk
                      position = get_position(opts)
                      direction = get_direction(opts)
                      max_count = opts.count.to_i
                      validate_max_count(max_count)
                      first_call = false
                    end

                    paginate_options(opts, position)
                  end
                processed_response =
                  EventStoreClient::GRPC::Shared::Streams::ProcessResponses.
                    new(config: config).
                    call(
                      response,
                      skip_deserialization,
                      skip_decryption
                    )

                yielder << processed_response if processed_response.any?
                raise StopIteration if end_reached?(response, max_count)

                position = calc_next_position(response, direction, stream_name)
                raise StopIteration if position.negative?
              end
            end
          end

          private

          # @param options [EventStore::Client::Streams::ReadReq::Options]
          # @param position [Integer, nil]
          # @return [EventStore::Client::Streams::ReadReq::Options, nil]
          def paginate_options(options, position)
            return unless position
            return paginate_all_options(options, position) if options.stream.nil?

            paginate_regular_options(options, position)
          end

          # @param options [EventStore::Client::Streams::ReadReq::Options]
          # @param position [Integer]
          # @return [EventStore::Client::Streams::ReadReq::Options]
          def paginate_all_options(options, position)
            options.all.position = EventStore::Client::Streams::ReadReq::Options::Position.new(
              commit_position: position
            )
            options
          end

          # @param options [EventStore::Client::Streams::ReadReq::Options]
          # @param position [Integer]
          # @return [EventStore::Client::Streams::ReadReq::Options]
          def paginate_regular_options(options, position)
            options.stream.revision = position
            options
          end

          # @param options [EventStore::Client::Streams::ReadReq::Options]
          # @return [Symbol] :Backwards or :Forwards
          def get_direction(options)
            return options.read_direction if options.read_direction

            DEFAULT_READ_DIRECTION
          end

          # @param options [EventStore::Client::Streams::ReadReq::Options]
          # @return [Integer, nil]
          def get_position(options)
            # If start position is set to :end - then we need to wait for first response to get
            # the value of the position
            return if options.all&.end
            return if options.stream&.end

            # In case if user has provided a starting position value
            return options.all&.position&.commit_position if options.all&.position&.commit_position
            return options.stream&.revision if options.stream&.revision

            0
          end

          # @param raw_events [Array<EventStore::Client::Streams::ReadResp>]
          # @param direction [Symbol] :Backwards or :Forwards
          # @param stream_name [String]
          # @return [Integer]
          def calc_next_position(raw_events, direction, stream_name)
            events = meaningful_events(raw_events).map(&:event)

            return next_position_for_all(events, direction) if stream_name == '$all'

            next_position_for_regular(events, direction)
          end

          # @param events [Array<EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent>]
          # @param direction [Symbol] :Backwards or :Forwards
          # @return [Integer]
          def next_position_for_all(events, direction)
            return event_or_link(events.last).commit_position if direction == DEFAULT_READ_DIRECTION

            event_or_link(events.first).commit_position
          end

          # @param events [Array<EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent>]
          # @param direction [Symbol] :Backwards or :Forwards
          # @return [Integer]
          def next_position_for_regular(events, direction)
            return event_or_link(events.last).stream_revision + 1 if direction == DEFAULT_READ_DIRECTION

            event_or_link(events.last).stream_revision - 1
          end

          # @param raw_events [Array<EventStore::Client::Streams::ReadResp>]
          # @return [Array<EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent>]
          def meaningful_events(raw_events)
            raw_events.select { |read_resp| read_resp.event&.event }
          end

          # @param raw_events [Array<EventStore::Client::Streams::ReadResp>]
          # @param max_count [Integer]
          # @return [Boolean]
          def end_reached?(raw_events, max_count)
            meaningful_events(raw_events).size < max_count
          end

          # @return [void]
          # @raise [RecordsLimitError] raises error in case if max_count is less than 2
          def validate_max_count(max_count)
            return if max_count >= 2

            raise(
              RecordsLimitError,
              'Pagination requires :max_count option to be greater than or equal to 2. ' \
              "Current value is `#{max_count}'."
            )
          end

          # Picks the correct object for later resolving of stream_revision from it. In case if we
          # deal with links - we should prefer a link over a linked event, because exactly it
          # contains correct stream revision of the stream we are reading from. Because if we pick
          # a linked event's stream_revision, then it will be a revision from the stream that event
          # belongs to - this can potentially create an infinite loop.
          # @param event [EventStore::Client::Streams::ReadResp::ReadEvent]
          # @return [EventStore::Client::Streams::ReadResp::ReadEvent::RecordedEvent]
          def event_or_link(event)
            event.link ? event.link : event.event
          end
        end
      end
    end
  end
end
# rubocop:enable all
