# frozen_string_literal: true

require 'event_store_client/adapters/http/commands/command'

require 'event_store_client/adapters/http/commands/persistent_subscriptions/create'
require 'event_store_client/adapters/http/commands/persistent_subscriptions/read'

require 'event_store_client/adapters/http/commands/projections/create'

require 'event_store_client/adapters/http/commands/streams/append'
require 'event_store_client/adapters/http/commands/streams/delete'
require 'event_store_client/adapters/http/commands/streams/link_to'
require 'event_store_client/adapters/http/commands/streams/read_all'
require 'event_store_client/adapters/http/commands/streams/read'
require 'event_store_client/adapters/http/commands/streams/tombstone'

require 'event_store_client/adapters/http/client'
