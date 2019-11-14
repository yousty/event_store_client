# frozen_string_literal: true

require 'dry-struct'

module EventStoreClient
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  class Configuration
    attr_accessor :host, :port, :per_page, :service_name, :mapper

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
