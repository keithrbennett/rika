# Requires the Tika jar file, either from the default location (packaged with this gem)
# or from an override specified in the TIKA_JAR_FILESPEC environment variable.
#
# @return absolute filespec of loaded Tika jar file
class TikaLoader
  def self.require_tika
    tika_jar_location_override = ENV['TIKA_JAR_FILESPEC']
    if tika_jar_location_override
      tika_jar_location = File.absolute_path(tika_jar_location_override)
      require tika_jar_location
      puts "Using Tika jar file at #{tika_jar_location_override}."
    else
      tika_jar_location = File.absolute_path('./java-lib/tika-app-1.24.1.jar')
      puts "Using Tika jar file at default location: #{tika_jar_location}"
      require default_tika_jar_location
    end
    tika_jar_location
  end
end