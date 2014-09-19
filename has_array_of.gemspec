$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "has_array_of/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "has_array_of"
  s.version     = HasArrayOf::VERSION
  s.author      = "Vladimir Kochnev"
  s.email       = "hashtable@yandex.ru"
  s.homepage    = "https://github.com/marshall-lee/has_array_of"
  s.summary     = "Associations on top of PostgreSQL arrays"
  s.description = "Adds possibility of has_many and belongs_to_many associations using PostgreSQL arrays of ids."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'pg'
  s.add_runtime_dependency 'activerecord', '>= 3.1'

  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'rspec-rails', '~> 3.1'
  s.add_development_dependency 'with_model'
end
