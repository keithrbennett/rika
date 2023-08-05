# frozen_string_literal: true

# This file is the top level file for the Rika gem.
# It requires the other files in the gem and provides the top level API.

# Raise an error if not running under JRuby.
unless RUBY_PLATFORM.match(/java/)
  raise "\n\n\nRika can only be run with JRuby! It needs access to the Java Virtual Machine.\n\n\n"
end

require 'rika/version'
require 'uri'
require 'open-uri'
require_relative 'rika/parser'
require_relative 'rika/parse_result'
require_relative 'rika/tika_loader'

TikaLoader.require_tika

# The top level module for the Rika gem.
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

  # Gets a ParseResult from parsing a document.
  #
  # @param [String] data_source file path or HTTP URL
  # @param [Integer] max_content_length maximum content length to return
  # @param [Detector] Tika detector (optional)
  # @return [ParseResult]
  def self.parse(data_source, max_content_length = -1, detector = DefaultDetector.new)
    Parser.new(data_source, max_content_length, detector).parse
  end

  # @return [String] version of loaded Tika jar file
  def self.tika_version
    Tika.java_class.package.implementation_version
  end

  # @return [String] language of passed text, as 2-character ISO 639-1 code
  def self.language(text)
    tika_language_detector.detect(text.to_java_string).get_language
  end

  # @return [Array<String,Hash>] content and metadata of file at specified location
  #
  # @deprecated - instead, get a ParseResult and access the content and metadata fields
  def self.parse_content_and_metadata(file_location, max_content_length = -1)
    result = parse(file_location, max_content_length)
    [result.content, result.metadata]
  end

  # @return [Hash] content and metadata of file at specified location
  #
  # @deprecated - instead, use a ParseResult or its to_h method
  def self.parse_content_and_metadata_as_hash(file_location, max_content_length = -1)
    result = parse(file_location, max_content_length)
    { content: result.content, metadata: result.metadata }
  end

  # @return [Parser] parser for resource at specified location
  #
  # @deprecated - instead, get a ParseResult and access the content field
  def self.parse_content(file_location, max_content_length = -1)
    parse(file_location, max_content_length).content
  end

  # Regarding max_content_length, the default is set at 0 to save unnecessary processing,
  # since the content is being ignored. However, the PDF metadata "pdf:unmappedUnicodeCharsPerPage"
  # and "pdf:charsPerPage" will be absent if the max_content_length is 0, and otherwise may differ
  # depending on the number of characters read.
  #
  # @deprecated - instead, get a ParseResult and access the metadata field
  def self.parse_metadata(file_location, max_content_length = 0)
    parse(file_location, max_content_length).metadata
  end

  def self.tika_language_detector
    @tika_language_detector ||= OptimaizeLangDetector.new.loadModels
  end
end
