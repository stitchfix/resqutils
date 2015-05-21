# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'resqutils/version'

Gem::Specification.new do |s|
  s.name        = "resqutils"
  s.version     = Resqutils::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Stitch Fix Engineering']
  s.email       = ['opensource@stitchfix.com']
  s.homepage    = "https://github.com/stitchfix/resqutils"
  s.summary     = "Utilities for using Resque in a Rails app"
  s.description = "Utilities for using Resque in a Rails app"
  s.rubyforge_project = "resqutils"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency("resque")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
end
