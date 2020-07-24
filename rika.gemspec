# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rika/version'

Gem::Specification.new do |gem|
  gem.name          = "rika"
  gem.version       = Rika::VERSION
  gem.authors       = ["Richard Nyström", "Keith Bennett"]
  gem.email         = ["ricny046@gmail.com", "keithrbennett@gmail.com"]
  gem.description   = %q{ A JRuby wrapper for Apache Tika to extract text and metadata from files of various formats. }
  gem.summary       = %q{ A JRuby wrapper for Apache Tika to extract text and metadata from files of various formats. }
  gem.homepage      = "https://github.com/keithrbennett/rika"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency "rspec", "~> 3.9"
  gem.add_development_dependency "rake", "~> 13.0"
  gem.platform = "java"
  gem.license = "Apache-2.0"
end

