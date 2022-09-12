# frozen_string_literal: true

module EventStoreClient
  module GRPC
    module Commands
      module Streams
        class LinkToMultiple < Command
          # @api private
          # @see {EventStoreClient::GRPC::Client#link_to}
          def call(stream_name, events, options:, &blk)
            result = []
            link_cmd = Commands::Streams::LinkTo.new(**connection_options)
            events.each.with_index do |event, index|
              response =
                link_cmd.call(stream_name, event, options: options) do |req_opts, proposed_msg_opts|
                  req_opts.options.revision += index if has_revision_option?(req_opts.options)

                  yield(req_opts, proposed_msg_opts) if blk
                end
              result.push(response)
              break if response.failure?
            end
            result
          end

          private

          # Even if #revision is not set explicitly - its value defaults to 0. Thus, you can't
          # detect whether #revision is set just by calling #revision method. Instead - check if
          # option does not set #no_stream, #any or #stream_exists options - they are self-exclusive
          # options and only one of them can be active at a time
          # @param options [EventStore::Client::Streams::AppendReq::Options]
          # @return [Boolean]
          def has_revision_option?(options)
            [options.no_stream, options.any, options.stream_exists].all?(&:nil?)
          end
        end
      end
    end
  end
end
