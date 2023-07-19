# encoding: utf-8

raise "You need to run JRuby to use Rika" unless RUBY_PLATFORM =~ /java/

require "rika/version"
require 'uri'
require 'open-uri'
require_relative 'rika/parser'
require_relative 'rika/tika_loader'

TikaLoader.require_tika

module Rika
  import java.io.FileInputStream
  import java.net.URL
  import org.apache.tika.Tika
  import org.apache.tika.detect.DefaultDetector
  import org.apache.tika.io.TikaInputStream
  import org.apache.tika.langdetect.optimaize.OptimaizeLangDetector
  import org.apache.tika.language.detect.LanguageDetector
  import org.apache.tika.language.detect.LanguageResult
  import org.apache.tika.metadata.Metadata


  def self.tika_version
    Tika.java_class.package.implementation_version
  end

  def self.parse_content_and_metadata(file_location, max_content_length = -1)
    parser = Parser.new(file_location, max_content_length)
    [parser.content, parser.metadata]
  end

  def self.parse_content_and_metadata_as_hash(file_location, max_content_length = -1)
    content, metadata = parse_content_and_metadata(file_location, max_content_length)
    { content: content, metadata: metadata }
  end

  def self.parse_content(file_location, max_content_length = -1)
    Parser.new(file_location, max_content_length).content
  end

  # Regarding max_content_length, the default is set at 0 to save unnecessary processing,
  # since the content is being ignored. However, the PDF metadata "pdf:unmappedUnicodeCharsPerPage"
  # and "pdf:charsPerPage" will be absent if the max_content_length is 0, and will be
  # ]may differ depending on
  # the number of characters read.
  def self.parse_metadata(file_location, max_content_length = 0)
    Parser.new(file_location, max_content_length).metadata
  end

  def self.tika_language_detector
    @tika_language_detector ||= OptimaizeLangDetector.new.loadModels
  end
end


