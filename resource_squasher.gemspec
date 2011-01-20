# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "resource_squasher/version"

Gem::Specification.new do |s|
  s.name        = "resource_squasher"
  s.version     = ResourceSquasher::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Noah Paessel"]
  s.email       = ["knowuh@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{rename and transform dependent file resources}
  s.description = %q{rename and transform dependent file resources}

  s.rubyforge_project = "resource_squasher"
  s.add_dependency('bundler')
  s.add_dependency('rake')
  s.add_dependency('thor')

  # actually, we need to patch FakeFS gem too...
  s.add_development_dependency('FakeFS')
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
