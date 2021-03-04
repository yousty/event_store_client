# frozen_string_literal: true

module EventStoreClient
  class ErrorHandler
    def call(error)
      puts error
      puts error.backtrace
    end
  end
end
