# frozen_string_literal: true

require "rika"

def file_path(*paths)
  File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *paths))
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # Enable the line below if you want ", focus: true" after a test declaration to
  # denote the only tests that will be run:
  # config.filter_run :focus

  config.order = 'random'
end
