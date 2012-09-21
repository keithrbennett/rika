raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'uri'
require 'net/http'
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

module Rika
  import org.apache.tika.metadata.Metadata
  import org.apache.tika.Tika
  class Parser
    
    def initialize(uri, max_content_length = -1)
      p = URI::Parser.new
      @uri = uri
      @max_content_length = max_content_length
      
      if File.exists?(@uri) # it's a file!
        self.perform_file
      elsif p.parse(@uri).scheme == 'http' || p.parse(@uri).scheme == 'https' # URL FTW!!
        self.perform_url
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
      if @metadata.get(name) == nil
        false
      else
        true
      end
    end

    protected
    
    def perform_file
      input_stream = nil
      begin
        input_stream = java.io.FileInputStream.new(java.io.File.new(@uri))
        @metadata = Metadata.new
        @metadata.set("filename", File.basename(@uri))
        @tika = Tika.new
        @content = @tika.parse_to_string(input_stream, @metadata, @max_content_length) 
      ensure
        input_stream.close
      end
    end


    def perform_url
      input_stream = nil
      begin
        uri = URI(@uri)
        res = Net::HTTP.get_response(uri)
        raise IOError, "File does not exist or can't be reached." if not res.is_a?(Net::HTTPSuccess)
        
        url = java.net.URL.new(@uri)
        @metadata = Metadata.new
        @metadata.set("url", @uri)
        @tika = Tika.new
        input_stream = @tika.parse(url)
        @content = @tika.parse_to_string(url) 
      ensure
        input_stream.close if not input_stream.nil?
      end
    end
  end
end
