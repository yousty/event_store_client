# frozen_string_literal: true

if ENV['TEST_COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-formatter-badge'

  SimpleCov.profiles.define 'event-store-client' do
    add_filter 'spec/'
    add_filter '/version.rb'
    track_files 'lib/**/*.rb'
  end

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::BadgeFormatter
    ]
  )

  # Target
  # SimpleCov.minimum_coverage 90

  SimpleCov.start 'event-store-client'
end

require 'event_store_client'
require 'pry'
require 'securerandom'
require 'webmock/rspec'
require 'webmock/rspec/matchers'

Dir[File.join(File.expand_path('.', __dir__), 'support/**/*.rb')].each { |f| require f }

EventStoreClient.configure do |config|
  config.eventstore_url = ENV.fetch('EVENTSTORE_URL') { 'http://localhost:2113' }
  config.adapter_type = :grpc
  config.eventstore_user = ENV.fetch('EVENTSTORE_USER') { 'admin' }
  config.eventstore_password = ENV.fetch('EVENTSTORE_PASSWORD') { 'changeit' }
  config.verify_ssl = false
  config.insecure = true
  config.service_name = ''
  config.error_handler = proc {}
  config.subscriptions_repo = EventStoreClient::CatchUpSubscriptions.new(
    connection: EventStoreClient.adapter,
    subscription_store: DummySubscriptionStore.new('dummy-subscription-store')
  )
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.include WebMock::API
  config.include WebMock::Matchers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.before do
    EventStoreClient.adapter.instance_variable_set(:@event_store, {})
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'tmp/spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = false

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.profile_examples = 10

  config.order = :random

  Kernel.srand config.seed

  config.before(:each, webmock: :itself.to_proc) do
    WebMock.enable!
  end

  config.after(:each, webmock: :itself.to_proc) do
    WebMock.disable!
  end

  config.around(:each, webmock: :itself.to_proc) do |example|
    example.run
    WebMock.reset!
  end
end
