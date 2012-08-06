# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scribble/version'

Gem::Specification.new do |gem|
  gem.name          = "scribble"
  gem.version       = Scribble::VERSION
  gem.authors       = ["Yasuhiro Asaka"]
  gem.email         = ["y.grauwoelfchen@gmail.com"]
  gem.summary       = %q{Todo application}
  gem.description   = %q{File based command line todo application.}
  gem.homepage      = "http://github.com/grauwoelfchen/scribble"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency 'slop', '>= 3.0'
  gem.add_dependency 'thor'
  gem.add_development_dependency 'rspec'
end

