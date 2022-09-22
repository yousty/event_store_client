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

require 'event_store_client/adapters/grpc/connection'
require 'event_store_client/adapters/grpc/discover'
require 'event_store_client/adapters/grpc/cluster/insecure_connection'
require 'event_store_client/adapters/grpc/cluster/secure_connection'
require 'event_store_client/adapters/grpc/cluster/queryless_discover'
require 'event_store_client/adapters/grpc/cluster/gossip_discover'
require 'event_store_client/adapters/grpc/cluster/member'

require 'event_store_client/adapters/grpc/command_registrar'
require 'event_store_client/adapters/grpc/commands/command'

require 'event_store_client/adapters/grpc/commands/gossip/cluster_info'

require 'event_store_client/adapters/grpc/commands/streams/append'
require 'event_store_client/adapters/grpc/commands/streams/append_multiple'
require 'event_store_client/adapters/grpc/commands/streams/delete'
require 'event_store_client/adapters/grpc/commands/streams/hard_delete'
require 'event_store_client/adapters/grpc/commands/streams/link_to'
require 'event_store_client/adapters/grpc/commands/streams/link_to_multiple'
require 'event_store_client/adapters/grpc/commands/streams/read'
require 'event_store_client/adapters/grpc/commands/streams/read_paginated'
require 'event_store_client/adapters/grpc/commands/streams/subscribe'

require 'event_store_client/adapters/grpc/client'
