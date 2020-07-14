# encoding: utf-8

raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'uri'
require 'open-uri'
require 'java'

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

# Heavily based on the Apache Tika API: http://tika.apache.org/1.5/api/org/apache/tika/Tika.html
module Rika
  import org.apache.tika.metadata.Metadata
  import org.apache.tika.Tika
  import org.apache.tika.language.LanguageIdentifier
  import org.apache.tika.detect.DefaultDetector
  import java.io.FileInputStream
  import java.net.URL

  def self.parse_content_and_metadata(file_location, max_content_length = -1)
    parser = Parser.new(file_location, max_content_length)
    [parser.content, parser.metadata]
  end

  def self.parse_content(file_location, max_content_length = -1)
    parser = Parser.new(file_location, max_content_length)
    parser.content
  end

  def self.parse_metadata(file_location)
    parser = Parser.new(file_location, 0)
    parser.metadata
  end

  class Parser

    def initialize(file_location, max_content_length = -1, detector = DefaultDetector.new)
      @uri = file_location
      @tika = Tika.new(detector)
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
      if file?
        @media_type ||= @tika.detect(java.io.File.new(@uri))
      else
        @media_type ||= @tika.detect(input_stream)
      end
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

    def language
      @lang ||= LanguageIdentifier.new(content)
      @lang.language
    end

    # @deprecated
    # https://tika.apache.org/1.9/api/org/apache/tika/language/LanguageIdentifier.html#isReasonablyCertain()
    # says: WARNING: Will never return true for small amount of input texts.
    # https://tika.apache.org/1.19/api/org/apache/tika/language/LanguageIdentifier.html
    # indicated that the LanguageIdentifier class used in this implementation is deprecated.
    # TODO: More research needed to see if an alternate implementation can be used.
    def language_is_reasonably_certain?
      @lang ||= LanguageIdentifier.new(content)
      @lang.is_reasonably_certain
    end

    protected

    def parse
      @content ||= @tika.parse_to_string(input_stream, @metadata_java).to_s.strip
    end

    def get_input_type
      if File.exists?(@uri) && File.directory?(@uri) == false
        :file
      elsif URI(@uri).is_a?(URI::HTTP) && open(@uri)
        :http
      else
        raise IOError, "Input (#{@uri}) is neither file nor http."
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
