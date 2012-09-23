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
  
  class Parser
    
    def initialize(uri, max_content_length = -1)
      p = URI::Parser.new
      @uri = uri
      @tika = Tika.new
      @tika.set_max_string_length(max_content_length)
      @metadata = Metadata.new
      
      if File.exists?(@uri)
        self.parse_file
      elsif p.parse(@uri).scheme == 'http' || p.parse(@uri).scheme == 'https'
        self.parse_url
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

    def available_metadata
      @metadata.names.to_a
    end

    def metadata_exists?(name)
      @metadata.get(name) != nil
    end

    protected
    
    def parse_file
      input_stream = java.io.FileInputStream.new(java.io.File.new(@uri))
      @metadata.set("filename", File.basename(@uri))
      @content = @tika.parse_to_string(input_stream, @metadata) 
    end

    def parse_url
      raise IOError, "File does not exist or can't be reached." if not Net::HTTP.get_response(URI(@uri)).is_a?(Net::HTTPSuccess)
      url = java.net.URL.new(@uri)
      input_stream = url.open_stream
      @metadata.set("url", @uri)
      @content = @tika.parse_to_string(input_stream, @metadata) 
    end
  end
end
