raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

module Rika
  import org.apache.tika.metadata.Metadata
  import org.apache.tika.Tika
  class Parser
    
    def initialize(filename, max_content_length = -1)
      if File.exists?(filename)
        @filename = filename
        @max_content_length = max_content_length
        self.perform
      else
        raise IOError, "File does not exist"
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
    
    def perform
      input_stream = nil
      begin
        input_stream = java.io.FileInputStream.new(java.io.File.new(@filename))
        @metadata = Metadata.new
        @metadata.set("filename", File.basename(@filename))
        @tika = Tika.new
        @content = @tika.parse_to_string(input_stream, @metadata, @max_content_length) 
      ensure
        input_stream.close  
      end
    end
  end
end
