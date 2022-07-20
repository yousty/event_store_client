# frozen_string_literal: true

require 'grpc'
require 'dry-monads'

require 'event_store_client/adapters/grpc/options/streams/read_options'
require 'event_store_client/adapters/grpc/options/streams/write_options'

require 'event_store_client/adapters/grpc/shared/event_deserializer'
require 'event_store_client/adapters/grpc/shared/options/stream_options'
require 'event_store_client/adapters/grpc/shared/options/filter_options'
require 'event_store_client/adapters/grpc/shared/streams/process_response'
require 'event_store_client/adapters/grpc/shared/streams/process_responses'

require 'event_store_client/adapters/grpc/commands/command'

require 'event_store_client/adapters/grpc/commands/streams/append'
require 'event_store_client/adapters/grpc/commands/streams/append_multiple'
require 'event_store_client/adapters/grpc/commands/streams/delete'
require 'event_store_client/adapters/grpc/commands/streams/hard_delete'
require 'event_store_client/adapters/grpc/commands/streams/link_to'
require 'event_store_client/adapters/grpc/commands/streams/link_to_multiple'
require 'event_store_client/adapters/grpc/commands/streams/read'
require 'event_store_client/adapters/grpc/commands/streams/read_paginated'
require 'event_store_client/adapters/grpc/commands/streams/subscribe'

require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/create'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/update'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/delete'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/read'

require 'event_store_client/adapters/grpc/commands/projections/create'
require 'event_store_client/adapters/grpc/commands/projections/update'
require 'event_store_client/adapters/grpc/commands/projections/delete'

require 'event_store_client/adapters/grpc/client'
