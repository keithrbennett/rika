# Requires the Tika jar file, either from the default location (packaged with this gem)
# or from an override specified in the TIKA_JAR_FILESPEC environment variable.
#
# @return absolute filespec of loaded Tika jar file
class TikaLoader
  def self.require_tika
    tika_jar_filespec = get_specified_tika_filespec

    begin
      abs_tika_jar_filespec = File.absolute_path(tika_jar_filespec)
      require abs_tika_jar_filespec
    rescue LoadError => e
      message = "Unable to load Tika jar file from #{tika_jar_filespec}."
      if tika_jar_filespec != abs_tika_jar_filespec
        message << "\nAbsolute filespec is #{abs_tika_jar_filespec}."
      end
      print_message_and_exit(message)
    end
    nil
  end

  def self.get_specified_tika_filespec
    tika_jar_filespec = ENV['TIKA_JAR_FILESPEC']
    not_specified = tika_jar_filespec.nil? || tika_jar_filespec.strip.empty?
    if not_specified
      message = 'Environment variable TIKA_JAR_FILESPEC is not set.'
      print_message_and_exit(message)
    end
    tika_jar_filespec
  end


  def self.formatted_error_message(message)
    banner = '!' * 79 # message.length
    <<~MESSAGE

        #{banner}
        #{message}
        #{banner}

    MESSAGE
  end

  def self.print_message_and_exit(message)
    $stderr.puts formatted_error_message(message)
    exit 1
  end
end