module Rika
  class Parser

    attr_reader :data_source, :tika, :metadata_java, :metadata_ruby, :input_type

    def initialize(data_source, max_content_length = -1, detector = DefaultDetector.new)
      @data_source = data_source
      @tika = Tika.new(detector)
      @tika.set_max_string_length(max_content_length)
      @metadata_java = nil
      @metadata_ruby = nil
      @input_type = get_input_type
    end

    # @return [String] content
    def content
      parse
      @content
    end

    # @return [Hash] metadata
    def metadata
      @metadata_ruby ||= begin
        parse
        metadata_java.names.each_with_object({}) do |name, m_ruby|
          m_ruby[name] = metadata_java.get(name)
        end
      end
    end

    # @return [String] media type
    def media_type
      @media_type ||= file? \
          ? tika.detect(java.io.File.new(data_source)) \
          : tika.detect(input_stream)
    end

    # @return [String] language of content, as 2-character ISO 639-1 code
    def language
      Rika.language(content)
    end

    # @return [Parser] self
    def parse
      unless @content
        @metadata_java = Metadata.new
        @content = tika.parse_to_string(input_stream, @metadata_java).to_s.strip
      end
      self
    end

    # @return [Symbol] input type (currently only :file and :http are supported)
    # @raise [IOError] if input is not a file or HTTP resource
    private def get_input_type
      if File.file?(data_source)
        :file
      elsif URI(data_source).is_a?(URI::HTTP) && URI.open(data_source)
        :http
      else
        raise IOError, "Input (#{data_source}) is not an available file or HTTP resource."
      end
    end

    # @return [InputStream] input stream from which data was or will be parsed
    private def input_stream
      file? \
          ? FileInputStream.new(java.io.File.new(data_source)) \
          : URL.new(data_source).open_stream
    end

    # @return [Boolean] true if, and only if, input is a file
    private def file?
      input_type == :file
    end
  end
end
