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

require 'pry'
require 'event_store_client'
require 'timecop'
require 'dry-schema'

Dir[File.join(File.expand_path('.', __dir__), 'support/**/*.rb')].each { |f| require f }

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
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

  config.before do
    TestHelper.configure_grpc
  end

  config.after do
    EventStoreClient.instance_variable_set(:@config, nil)
    EventStoreClient::GRPC::Discover.instance_variable_set(:@current_member, nil)
    EventStoreClient::GRPC::Discover.instance_variable_set(:@exception, nil)
    DummyRepository.reset
  end

  config.around(timecop: :itself.to_proc) do |example|
    if example.metadata[:timecop].is_a?(Time)
      Timecop.freeze(example.metadata[:timecop]) { example.run }
    else
      Timecop.freeze { example.run }
    end
  end
  config.include EventHelpers
end
