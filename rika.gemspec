# frozen_string_literal: true

require 'English'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rika/version'

Gem::Specification.new do |gem|
  gem.name          = 'rika'
  gem.version       = Rika::VERSION
  gem.authors       = ['Richard Nyström', 'Keith Bennett']
  gem.email         = ['ricny046@gmail.com', 'keithrbennett@gmail.com']
  gem.description   = 'A JRuby wrapper for Apache Tika to extract text and metadata from files of various formats.'
  gem.summary       = 'A JRuby wrapper for Apache Tika to extract text and metadata from files of various formats.'
  gem.homepage      = 'https://github.com/keithrbennett/rika'
  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.require_paths = ['lib']
  gem.add_dependency 'awesome_print'
  gem.platform = 'java'
  gem.license = 'MIT'
  gem.metadata['rubygems_mfa_required'] = 'true'

  # NOTE: I am excluding the Ruby version constraint because this gem runs only in JRuby, and I don't know the
  # minimum version requirement, and don't want to exclude use of any versions that might work.

  gem.post_install_message = <<~MESSAGE

    Using the rika gem requires that you:
      1) download the Apache Tika tika-app jar file from https://tika.apache.org/download.html
      2) place it somewhere accessible to the running application
      3) specify its location in the TIKA_JAR_FILESPEC environment variable

  MESSAGE
end
