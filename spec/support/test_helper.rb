# frozen_string_literal: true

class TestHelper
  class << self
    def configure_grpc
      EventStoreClient.configure do |config|
        config.eventstore_url =
          ENV.fetch('EVENTSTORE_URL') { 'esdb://localhost:2115/?tls=false&timeout=1000' }
        config.logger = ENV['DEBUG'] ? Logger.new(STDOUT) : DummyLogger
      end
    end

    def clean_up_grpc_config
      EventStoreClient.instance_variable_set(:@config, nil)
      EventStoreClient.init_default_config
      EventStoreClient::GRPC::Discover.instance_variable_set(:@semaphore, nil)
      EventStoreClient::GRPC::Discover.instance_variable_set(:@current_member, nil)
      EventStoreClient::GRPC::Discover.instance_variable_set(:@exception, nil)
      EventStoreClient::GRPC::Discover.init_default_discover_vars
    end

    def root_path
      File.expand_path('../..', __dir__)
    end
  end
end
