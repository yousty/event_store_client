# frozen_string_literal: true

require 'dry-struct'
require 'singleton'

module EventStoreClient
  class Configuration
    include Singleton

    attr_accessor :host, :port, :per_page, :service_name, :mapper

    def configure
      yield(self) if block_given?
    end

    private

    def initialize
      @host = 'http://localhost'
      @port = 2113
      @per_page = 20
      @mapper = Mapper::Default.new
      @service_name = 'default'
    end
  end
end
