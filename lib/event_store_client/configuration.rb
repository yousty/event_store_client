# frozen_string_literal: true

require 'dry-struct'
require 'singleton'

module EventStoreClient
  class Configuration
    include Singleton

    attr_accessor :host, :port, :per_page, :service_name, :mapper, :error_handler, :pid_path

    def configure
      yield(self) if block_given?
    end

    private

    def initialize
      @host = 'http://localhost'
      @port = 2113
      @per_page = 20
      @pid_path = 'tmp/pool.pid'
      @mapper = Mapper::Default.new
      @service_name = 'default'
      @error_handler = nil
    end
  end
end
