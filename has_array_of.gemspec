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

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  unless RUBY_PLATFORM =~ /java/
    s.add_dependency 'pg'
  else
    s.add_dependency 'activerecord-jdbcpostgresql-adapter'
  end

  s.add_dependency 'activerecord', '>= 4.2'
  s.add_dependency 'railties', '>= 4.2'

  s.add_development_dependency 'bundler', '>= 1.17'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.9.0'
  s.add_development_dependency 'database_cleaner', '~> 1.7.0'
  s.add_development_dependency 'with_model', '~> 2.1.2'
end
