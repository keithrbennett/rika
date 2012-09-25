raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'uri'
require 'net/http'
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

# Heavily based on the Apache Tika API: http://tika.apache.org/1.2/api/org/apache/tika/Tika.html
module Rika
  import org.apache.tika.metadata.Metadata
  import org.apache.tika.Tika
  import java.io.FileInputStream
  import java.net.URL
  
  class Parser
    
    def initialize(file_location, max_content_length = -1)
      @uri = file_location
      @tika = Tika.new
      @tika.set_max_string_length(max_content_length)
      @metadata = Metadata.new
      
      if File.exists?(@uri)
        self.parse
      elsif ["http", "https"].include?(URI::Parser.new.parse(@uri).scheme) 
        raise IOError, "File does not exist or can't be reached." if not Net::HTTP.get_response(URI(@uri)).is_a?(Net::HTTPSuccess)
        self.parse
      else
        raise IOError, "File does not exist or can't be reached."
      end
    end

    def content
      @content.to_s.strip
    end

    def metadata
      metadata_hash = {}
      
      @metadata.names.each do |name|
        metadata_hash[name] = @metadata.get(name) 
      end

      metadata_hash
    end

    def media_type
      @media_type
    end

    def available_metadata
      @metadata.names.to_a
    end

    def metadata_exists?(name)
      @metadata.get(name) != nil
    end

    protected
    
    def parse
      @media_type = @tika.detect(input_stream)
      @content = @tika.parse_to_string(input_stream, @metadata) 
    end

    def input_stream
      if File.exists?(@uri)
        FileInputStream.new(java.io.File.new(@uri))
      else 
        URL.new(@uri).open_stream
      end
    end
  end
end
