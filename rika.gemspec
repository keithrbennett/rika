# frozen_string_literal: true

lib = File.expand_path('../lib', __dir__)
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
  gem.add_dependency 'webrick', '~> 1.6'
  gem.add_dependency "awesome_print"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "rspec", "~> 3.9"
  gem.add_development_dependency "rake", "~> 13.0"
  gem.platform = "java"
  gem.license = "Apache-2.0"

  gem.post_install_message = <<~MESSAGE

    Using the rika gem requires that you:
      1) download the Apache Tika tika-app jar file from https://tika.apache.org/download.html
      2) place it somewhere accessible to the running application
      3) specify its location in the TIKA_JAR_FILESPEC environment variable

  MESSAGE
end

