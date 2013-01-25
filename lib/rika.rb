# encoding: utf-8

raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'uri'
require 'net/http'
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

# Heavily based on the Apache Tika API: http://tika.apache.org/1.3/api/org/apache/tika/Tika.html
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
      @metadata_java = Metadata.new
      @metadata_ruby = nil
      @input_type = get_input_type
    end

    def content
      self.parse
      @content 
    end

    def metadata
      unless @metadata_ruby
        self.parse
        @metadata_ruby = {}
      
        @metadata_java.names.each do |name|
          @metadata_ruby[name] = @metadata_java.get(name)
        end
      end
      @metadata_ruby
    end

    def media_type
      @media_type ||= @tika.detect(input_stream) 
    end

    def available_metadata
      metadata.keys
    end

    def metadata_exists?(name)
      metadata[name] != nil
    end

    def file?
      @input_type == :file
    end

    protected
    
    def parse
      @content ||= @tika.parse_to_string(input_stream, @metadata_java).to_s.strip
    end

    def get_input_type
      if File.exists?(@uri) && File.directory?(@uri) == false
        :file
      elsif URI(@uri).scheme == "http" && Net::HTTP.get_response(URI(@uri)).is_a?(Net::HTTPSuccess)
        :http
      else
        raise IOError, "Input (#{@uri})is neither file nor http."
      end
    end

    def input_stream
      if file?
        FileInputStream.new(java.io.File.new(@uri))
      else # :http
        URL.new(@uri).open_stream
      end
    end
  end
end
