# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'resqutils/version'

Gem::Specification.new do |s|
  s.name        = "resqutils"
  s.version     = Resqutils::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stitch Fix Engineering","Dave Copeland","Simeon Willbanks"]
  s.email       = ["opensource@stitchfix.com","davetron5000@gmail.com","simeon@simeons.net"]
  s.license     = "Apache License Version 2.0, January 2004"
  s.homepage    = "https://github.com/stitchfix/resqutils"
  s.summary     = "Utilities for using Resque in a Rails app"
  s.description = "Utilities for using Resque in a Rails app"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = []
  s.require_paths = ["lib"]
  s.add_runtime_dependency("resque")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec")
  s.add_development_dependency("fakeredis")
  s.add_development_dependency('rspec_junit_formatter')
end
