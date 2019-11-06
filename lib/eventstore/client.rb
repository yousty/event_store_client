# frozen_string_literal: true

module Eventstore
  module Client
  end
end

require 'eventstore/client/types'
require 'eventstore/client/event'

require 'eventstore/client/serializer/json'

require 'eventstore/client/event_mapper/default'

require 'eventstore/client/endpoint'

require 'eventstore/client/api/request_method'
require 'eventstore/client/api/connection'
require 'eventstore/client/api/client'

require 'eventstore/client/connection'