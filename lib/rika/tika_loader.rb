# frozen_string_literal: true

# Requires the Tika jar file, either from the default location (packaged with this gem)
# or from an override specified in the TIKA_JAR_FILESPEC environment variable.

require_relative 'tika_load_error'

module Rika
  # This class handles the loading of the Apache Tika Java jar file.
  # It is not intended to be instantiated. Instead, call the only public class method, `require_tika`.
  class TikaLoader
    # @return [String] absolute filespec of loaded Tika jar file
    # @raise [TikaLoadError] if the Tika jar file cannot be loaded
    def self.require_tika
      tika_jar_filespec = specified_tika_filespec

      begin
        abs_tika_jar_filespec = File.absolute_path(tika_jar_filespec)
        require abs_tika_jar_filespec
        abs_tika_jar_filespec
      rescue LoadError
        message = "Unable to load Tika jar file from #{tika_jar_filespec}."
        if tika_jar_filespec != abs_tika_jar_filespec
          message += "\nAbsolute filespec is #{abs_tika_jar_filespec}."
        end
        raise TikaLoadError.new(message)
      end
    end

    # Gets the Tika jar filespec from the TIKA_JAR_FILESPEC environment variable,
    # and prints an error message and exits if it is not set.
    #
    # @return [String] Tika jar filespec from env var TIKA_JAR_FILESPEC
    # @raise [TikaLoadError] if the Tika jar file was not specified
    private_class_method def self.specified_tika_filespec
      tika_jar_filespec = ENV['TIKA_JAR_FILESPEC']
      not_specified = tika_jar_filespec.nil? || tika_jar_filespec.strip.empty?
      raise TikaLoadError.new('Environment variable TIKA_JAR_FILESPEC is not set.') if not_specified

      tika_jar_filespec
    end

    # Formats an error message for printing to stderr.
    #
    # @param [String] message the error message
    # @return [String] the formatted error message
    private_class_method def self.formatted_error_message(message)
      banner = '!' * 79 # message.length
      <<~MESSAGE

        #{banner}
        #{message}
        #{banner}

      MESSAGE
    end

    # Prints an error message to stderr and exits with a non-zero exit code.
    private_class_method def self.print_message_and_exit(message)
      warn formatted_error_message(message)
      exit 1
    end
  end
end
