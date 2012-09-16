raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'java' 

Dir[File.join(File.dirname(__FILE__), "*.jar")].each do |jar|
  require jar
end

module Rika
	import org.apache.tika.sax.BodyContentHandler
	import org.apache.tika.parser.AutoDetectParser
	import org.apache.tika.metadata.Metadata

  class Parser
  	
  	def initialize(filename)
  		@filename = filename
			self.perform
  	end

  	def content
  		@content.to_s
  	end

  	def metadata
  		metadata_hash = {}
  		
  		@metadata.names.each do |name|
  			metadata_hash[name] = @metadata.get(name) 
  		end

  		metadata_hash
  	end

  	protected
		
		def perform
			input_stream = java.io.FileInputStream.new(java.io.File.new(@filename))
			@metadata = Metadata.new
			@metadata.set("filename", File.basename(@filename))
			@parser = AutoDetectParser.new
			@content = BodyContentHandler.new
			@parser.parse(input_stream, @content, @metadata)
			input_stream.close
		end
  end
end
