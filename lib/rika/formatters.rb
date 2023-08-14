# frozen_string_literal: true

module Rika
  class Formatters
    AWESOME_PRINT = ->(object) { object.ai }
    INSPECT       = ->(object) { object.inspect }
    JSON          = ->(object) { object.to_json }
    PRETTY_JSON   = ->(object) { JSON.pretty_generate(object) }
    TO_S          = ->(object) { object.to_s }
    YAML          = ->(object) { object.to_yaml }

    # A hash of formatters, keyed by the format character.
    # The value is a lambda that takes the object to be formatted as a parameter.
    # @return [Hash] the hash of formatters
    OPTION_LOOKUP_TABLE = {
      'a' => AWESOME_PRINT,
      'i' => INSPECT,
      'j' => JSON,
      'J' => PRETTY_JSON,
      't' => TO_S,
      'y' => YAML
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
