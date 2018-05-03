require 'fakeredis'
require 'resque'
require 'resqutils'
require 'resqutils/spec'

GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..'))
Dir["#{GEM_ROOT}/spec/support/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.order = "random"
  Kernel.srand config.seed
end
