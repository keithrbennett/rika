# frozen_string_literal: true

require 'simplecov'
SimpleCov.start { add_filter '/spec/' }

require 'rika'

def fixture_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # Enable the line below if you want ", focus: true" after a test declaration to
  # denote the only tests that will be run:
  # config.filter_run :focus

  config.order = 'random'
  config.example_status_persistence_file_path = 'spec/rspec-failed-tests-control-file.txt'
end

Rika.init
