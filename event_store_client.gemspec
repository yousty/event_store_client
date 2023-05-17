# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'event_store_client/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'event_store_client'
  spec.version     = EventStoreClient::VERSION
  spec.authors     = ['Sebastian Wilgosz']
  spec.email       = ['sebastian@driggl.com']
  spec.homepage    = 'https://github.com/yousty/event_store_client'
  spec.summary     = 'Ruby integration for https://eventstore.org'
  spec.description = 'Easy to use client for event-sources applications written in ruby'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'LICENSE.txt', 'Rakefile', 'README.md', 'docs/**/*']

  spec.add_dependency 'grpc', '~> 1.0'

  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'simplecov-formatter-badge', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'grpc-tools', '~> 1.46'
  spec.add_development_dependency 'timecop', '~> 0.9.5'
  spec.add_development_dependency 'dry-schema', '~> 1.13.0'
  spec.add_development_dependency 'dry-monads', '~> 1.6'
end
