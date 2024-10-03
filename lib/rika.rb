# frozen_string_literal: true

# This file is the top level file for the Rika gem.
# It requires the other files in the gem and provides the top level API.
# It also provides the top level module for the gem.
require 'rika/version'
require_relative 'rika/parser'
require_relative 'rika/tika_loader'

# The top level module for the Rika gem.
module Rika
  PROJECT_URL = 'https://github.com/keithrbennett/rika'

  # Loads the Tika jar file and imports the needed Java classes.
  # @return [Module] the Rika module, for chaining
  def self.init
    return if @initialized

    Rika.raise_unless_jruby

    Rika::TikaLoader.require_tika
    import java.io.FileInputStream
    import java.net.URL
    import org.apache.tika.Tika
    import org.apache.tika.detect.DefaultDetector
    import org.apache.tika.io.TikaInputStream
    import org.apache.tika.langdetect.optimaize.OptimaizeLangDetector
    import org.apache.tika.language.detect.LanguageDetector
    import org.apache.tika.language.detect.LanguageResult
    import org.apache.tika.metadata.Metadata

    @initialized = true
    self
  end

  # Gets a ParseResult from parsing a document.
  #
  # @param [String] data_source file path or HTTP(s) URL
  # @param [Boolean] key_sort whether to sort the keys in the metadata hash, defaults to true
  # @param [Integer] max_content_length maximum content length to return, defaults to all
  # @param [Detector] detector Tika detector, defaults to DefaultDetector
  # @return [ParseResult]
  def self.parse(data_source, key_sort: true, max_content_length: -1, detector: nil)
    init
    detector ||= DefaultDetector.new
    parser = Parser.new(data_source, key_sort: key_sort, max_content_length: max_content_length, detector: detector)
    parser.parse
  end

  # @return [String] version of loaded Tika jar file
  def self.tika_version
    init
    Tika.java_class.package.implementation_version
  end

  # @param [String] text text to detect language of
  # @return [String] language of passed text, as 2-character ISO 639-1 code
  def self.language(text)
    init
    tika_language_detector.detect(text.to_java_string).get_language
  end

  # @param [String] data_source file path or HTTP URL
  # @return [Array<String,Hash>] content and metadata of file at specified location
  #
  # @deprecated Instead, get a ParseResult and access the content and metadata fields.
  def self.parse_content_and_metadata(data_source, max_content_length: -1)
    init
    result = parse(data_source, max_content_length: max_content_length)
    [result.content, result.metadata]
  end

  # @param [String] data_source file path or HTTP URL
  # @return [Hash] content and metadata of file at specified location
  #
  # @deprecated Instead, use a ParseResult or its to_h method.
  def self.parse_content_and_metadata_as_hash(data_source, max_content_length: -1)
    init
    result = parse(data_source, max_content_length: max_content_length)
    { content: result.content, metadata: result.metadata }
  end

  # @param [String] data_source file path or HTTP URL
  # @return [Parser] parser for resource at specified location
  #
  # @deprecated Instead, get a ParseResult and access the content field
  def self.parse_content(data_source, max_content_length: -1)
    init
    parse(data_source, max_content_length: max_content_length).content
  end

  # Regarding max_content_length, the default is set at 0 to save unnecessary processing,
  # since the content is being ignored. However, the PDF metadata "pdf:unmappedUnicodeCharsPerPage"
  # and "pdf:charsPerPage" will be absent if the max_content_length is 0, and otherwise may differ
  # depending on the number of characters read.
  #
  # @deprecated Instead, get a ParseResult and access the metadata field
  def self.parse_metadata(data_source, max_content_length: -1)
    init
    parse(data_source, max_content_length: max_content_length).metadata
  end

  # @return [Detector] Tika detector
  def self.tika_language_detector
    init
    @tika_language_detector ||= OptimaizeLangDetector.new.loadModels
  end

  # Raise an error if not running under JRuby.
  def self.raise_unless_jruby
    unless RUBY_PLATFORM.match(/java/)
      raise "\n\n\nRika can only be run with JRuby! It needs access to the Java Virtual Machine.\n\n\n"
    end
  end
end
