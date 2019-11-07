$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "event_store_client/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "event_store_client"
  spec.version     = EventStoreClient::VERSION
  spec.authors     = ["Sebastian Wilgosz"]
  spec.email       = ["sebastian@driggl.com"]
  spec.homepage    = "https://github.com/yousty/event_store_client"
  spec.summary     = "Ruby integration for https://eventstore.org"
  spec.description = "Easy to use client for event-sources applications written in ruby"
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rss", "~> 0.2.8"
  spec.add_dependency "faraday", "~> 0.17.0"
  spec.add_dependency "dry-struct", "~> 1.1.1"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
end
