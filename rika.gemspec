# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rika/version'

Gem::Specification.new do |gem|
  gem.name          = "rika"
  gem.version       = Rika::VERSION
  gem.authors       = ["Richard Nyström"]
  gem.email         = ["ricny046@gmail.com"]
  gem.description   = %q{ A JRuby wrapper for Apache Tika to extract text and metadata from various file formats. }
  gem.summary       = %q{ A JRuby wrapper for Apache Tika to extract text and metadata from various file formats. }
  gem.homepage      = "https://github.com/ricn/rika"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency "rspec"
  gem.platform = "java"
end
