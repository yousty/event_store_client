require 'grpc'
require 'event_store_client/value_objects/read_direction.rb'
require 'event_store_client/adapters/grpc/generated/shared_pb.rb'
require 'event_store_client/adapters/grpc/generated/streams_pb.rb'
require 'event_store_client/adapters/grpc/generated/streams_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/streams/append'
require 'event_store_client/adapters/grpc/commands/streams/delete'
require 'event_store_client/adapters/grpc/commands/streams/read'
require 'event_store_client/adapters/grpc/commands/streams/read_all'
require 'event_store_client/adapters/grpc/commands/streams/tombstone'

require 'event_store_client/adapters/grpc/generated/persistent_pb.rb'
require 'event_store_client/adapters/grpc/generated/persistent_services_pb.rb'

require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/create'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/update'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/delete'
require 'event_store_client/adapters/grpc/commands/persistent_subscriptions/read'

require 'event_store_client/adapters/grpc/commands/projections/create'
require 'event_store_client/adapters/grpc/commands/projections/update'
require 'event_store_client/adapters/grpc/commands/projections/delete'
require 'event_store_client/adapters/grpc/client'