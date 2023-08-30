# frozen_string_literal: true

require 'uri'
require_relative 'parse_result'

module Rika
  # Parses a document and returns a ParseResult.
  # This class is intended to be used only by the Rika module, not by users of the gem,
  # who should instead call `Rika.parse`.
  class Parser
    # @param [String] data_source file path or HTTP(s) URL
    # @param [Boolean] key_sort whether to sort the keys in the metadata hash, defaults to true
    # @param [Integer] max_content_length maximum content length to return, defaults to all
    # @param [Detector] detector Tika detector, defaults to DefaultDetector
    def initialize(data_source, key_sort: true, max_content_length: -1, detector: DefaultDetector.new)
      @data_source = data_source
      @key_sort = key_sort
      @max_content_length = max_content_length
      @detector = detector
      @input_type = data_source_input_type
      @tika = Tika.new(@detector)
    end

    # Entry point method for parsing a document
    # @return [ParseResult] parse result
    def parse
      metadata_java = Metadata.new
      @tika.set_max_string_length(@max_content_length)
      content = with_input_stream { |stream| @tika.parse_to_string(stream, metadata_java) }
      language = Rika.language(content)
      metadata_java.set('rika:language', language)
      metadata_java.set('rika:data-source', @data_source)
      metadata = metadata_java_to_ruby(metadata_java)
      metadata = metadata.sort_by { |key, _value| key }.to_h if @key_sort

      ParseResult.new(
        content:            content,
        metadata:           metadata,
        metadata_java:      metadata_java,
        content_type:       metadata['Content-Type'],
        language:           language,
        input_type:         @input_type,
        data_source:        @data_source,
        max_content_length: @max_content_length
      )
    end

    # @param [Metadata] metadata_java a Tika Java metadata instance populated by the parse and added to by this class
    # @return [Hash] a Ruby hash containing the data of the Java Metadata instance
    private def metadata_java_to_ruby(metadata_java)
      metadata_java.names.each_with_object({}) do |name, m_ruby|
        m_ruby[name] = metadata_java.get(name)
      end
    end

    # @return [Symbol] input type (currently only :file and :http are supported)
    # @raise [IOError] if input is not a file or HTTP resource
    private def data_source_input_type
      if File.file?(@data_source)
        :file
      elsif URI(@data_source).is_a?(URI::HTTP)
        :http
      else
        raise IOError, "Input (#{@data_source}) is not an available file or HTTP resource."
      end
    end

    # * Creates and opens an input stream from the configured resource.
    # * Yields that stream to the passed code block.
    # * Then closes the stream.
    # @return [Object] the value returned by the passed code block
    private def with_input_stream
      input_stream = if @input_type == :file
        FileInputStream.new(java.io.File.new(@data_source))
      else
        URL.new(@data_source).open_stream
      end

      yield input_stream
    ensure
      input_stream.close if input_stream.respond_to?(:close)
    end
  end
end
