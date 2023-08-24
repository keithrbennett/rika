# frozen_string_literal: true

require 'json'
require 'yaml'
require 'awesome_print'

module Rika
  # This module manages the formatters used to format the output of the Rika command line application.
  class Formatters
    AWESOME_PRINT_FORMATTER = ->(object) { object.ai }
    INSPECT_FORMATTER       = ->(object) { object.inspect }
    JSON_FORMATTER          = ->(object) { object.to_json }
    PRETTY_JSON_FORMATTER   = ->(object) { JSON.pretty_generate(object) }
    TO_S_FORMATTER          = ->(object) { object.to_s }
    YAML_FORMATTER          = ->(object) { object.to_yaml }

    # A hash of formatters, keyed by the format character.
    # The value is a lambda that takes the object to be formatted as a parameter.
    # @return [Hash] the hash of formatters
    OPTION_LOOKUP_TABLE = {
      'a' => AWESOME_PRINT_FORMATTER,
      'i' => INSPECT_FORMATTER,
      'j' => JSON_FORMATTER,
      'J' => PRETTY_JSON_FORMATTER,
      't' => TO_S_FORMATTER,
      'y' => YAML_FORMATTER
    }

    # A hash containing the require statements needed to use each formatter.
    REQUIRED_REQUIRE = {
      'a' => 'awesome_print',
      'j' => 'json',
      'J' => 'json',
      'y' => 'yaml'
    }

    VALID_OPTION_CHARS = OPTION_LOOKUP_TABLE.keys

    # Gets the formatter lambda for the given option character.
    # Also, requires the necessary library, if any.
    # @param [String] option_char the option character
    # @return [Lambda] the formatter lambda
    # @raise [RuntimeError] if the option character is invalid
    def self.get(option_char)
      raise "Invalid option char: #{option_char}" unless VALID_OPTION_CHARS.include?(option_char)
      req = REQUIRED_REQUIRE[option_char]
      require req if req
      OPTION_LOOKUP_TABLE[option_char]
    end
  end
end
