begin
  require 'rubygems'
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

task default: :spec

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'HasArrayOf'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

Bundler::GemHelper.install_tasks

task 'db:setup' do
  cmd = "createdb"

  username = ENV['POSTGRES_USERNAME']
  cmd << " -U #{username}" if username

  cmd << " has_array_of_test"

  if system(cmd)
    puts 'Database has_array_of_test was successfully created.'
  end
end
