# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class ReadPaginated < Command
          RecordsLimitError = Class.new(StandardError)

          # @api private
          # @see {EventStoreClient::GRPC::Client#read_paginated}
          def call(stream_name, options:, skip_deserialization:, skip_decryption:, &blk)
            position, direction, max_count = nil
            Enumerator.new do |y|
              loop do
                response =
                  Read.new.call(
                    stream_name,
                    options: options,
                    skip_deserialization: true,
                    skip_decryption: true
                  ) do |opts|
                    yield opts if block_given?
                    position ||= get_position(opts)
                    direction ||= get_direction(opts)
                    max_count ||= opts.count.to_i

                    raise(
                      RecordsLimitError,
                      "Pagination requires :max_count option to be greater than or equal to 2. Current value is `#{max_count}'."
                    ) if max_count < 2
                    paginate_options(opts, position)
                  end
                if response.success?
                  processed_response =
                    EventStoreClient::GRPC::Shared::Streams::ProcessResponses.new.call(
                      response.success,
                      skip_deserialization,
                      skip_decryption
                    )
                  y << processed_response if processed_response.success.any?
                  raise StopIteration if end_reached?(response.success, max_count)

                  position = calc_next_position(response.success, direction, stream_name)
                  raise StopIteration if position.negative?
                else
                  y << response
                  raise StopIteration
                end
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

            :Forwards
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
            events = meaningful_events(raw_events).map { |e| e.event.event }

            if stream_name == '$all'
              return events.last.commit_position if direction == :Forwards

              events.first.commit_position
            else
              return events.last.stream_revision + 1 if direction == :Forwards

              events.last.stream_revision - 1
            end
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
        end
      end
    end
  end
end
