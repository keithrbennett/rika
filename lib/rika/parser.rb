# frozen_string_literal: true

require_relative 'parse_result'

module Rika
  # Parses a document and returns a ParseResult.
  # This class is intended to be used only by the Rika module, not by users of the gem.
  class Parser
    # @param [String] data_source file path or HTTP URL
    # @param [Integer] max_content_length maximum content length to return
    # @param [Detector] Tika detector

    def initialize(data_source, max_content_length = -1, detector = DefaultDetector.new)
      @data_source = data_source
      @max_content_length = max_content_length
      @detector = detector
    end

    def parse
      metadata_java = Metadata.new
      tika = Tika.new(@detector)
      tika.set_max_string_length(@max_content_length)
      input_type = data_source_input_type
      media_type = tika.detect(
        input_type == :file ? java.io.File.new(@data_source) : URL.new(@data_source)
      )
      content = tika_parse(input_type, metadata_java, tika)

      ParseResult.new(
        content:            content,
        metadata:           metadata_java_to_ruby(metadata_java),
        metadata_java:      metadata_java,
        media_type:         media_type,
        language:           Rika.language(content),
        input_type:         input_type,
        data_source:        @data_source,
        max_content_length: @max_content_length
      )
    end

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
      elsif URI(@data_source).is_a?(URI::HTTP) # && URI.parse(@data_source).open
        :http
      else
        raise IOError, "Input (#{@data_source}) is not an available file or HTTP resource."
      end
    end

    # @param [Symbol] input_type input type (currently only :file and :http are supported)
    # @return [InputStream] input stream from which data can be parsed
    private def create_input_stream(input_type)
      if input_type == :file
        FileInputStream.new(java.io.File.new(@data_source))
      else
        URL.new(@data_source).open_stream
      end
    end

    private def tika_parse(input_type, metadata_java, tika)
      begin
        input_stream = create_input_stream(input_type)
        content = tika.parse_to_string(input_stream, metadata_java).to_s.strip
      ensure
        input_stream.close if input_stream.respond_to?(:close)
      end
      content
    end
  end
end
