begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require 'rubygems/package_task'
require 'rspec/core/rake_task'

# Fix for NoMethodError: undefined method `last_comment'
# Deprecated in Rake 12.x
module FixForRakeLastComment
  def last_comment
    last_description
  end
end
Rake::Application.send :include, FixForRakeLastComment
### end of fix

RSpec::Core::RakeTask.new(:spec)

require 'rdoc/task'

include Rake::DSL

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ExtraExtra'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Bundler::GemHelper.install_tasks

task :default => :spec
