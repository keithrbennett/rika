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
    FORMATTER_LOOKUP_TABLE = {
      'a' => AWESOME_PRINT_FORMATTER,
      'i' => INSPECT_FORMATTER,
      'j' => JSON_FORMATTER,
      'J' => PRETTY_JSON_FORMATTER,
      't' => TO_S_FORMATTER,
      'y' => YAML_FORMATTER
    }

    VALID_OPTION_CHARS = FORMATTER_LOOKUP_TABLE.keys

    # Gets the formatter lambda for the given option character.
    # @param [String] option_char the option character
    # @return [Lambda] the formatter lambda
    # @raise [KeyError] if any option character is invalid
    def self.get(option_char)
      FORMATTER_LOOKUP_TABLE.fetch(option_char)
    end
  end
end
