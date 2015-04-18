$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "shopifyconnect/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "shopifyconnect"
  s.version     = Shopifyconnect::VERSION
  s.authors     = ["choonkeat"]
  s.email       = ["choonkeat@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "a Rails engine to simplify integration with Shopify."
  s.description = "a Rails engine to simplify integration with Shopify."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.0"
  s.add_dependency "shopify_api"
  s.add_dependency "slim-rails"
  s.add_dependency "sass-rails"
  s.add_dependency "jquery-rails"
  s.add_dependency "aasm"
end
