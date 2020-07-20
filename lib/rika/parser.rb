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

    def content
      parse
      @content
    end

    def metadata
      unless @metadata_ruby
        parse
        @metadata_ruby = @metadata_java.names.each_with_object({}) do |name, m_ruby|
          m_ruby[name] = @metadata_java.get(name)
        end
      end
      @metadata_ruby
    end


    def media_type
      @media_type ||= file? \
          ? @tika.detect(java.io.File.new(@data_source)) \
          : @media_type ||= @tika.detect(input_stream)
    end

    # @deprecated
    def available_metadata
      metadata.keys
    end

    # @deprecated
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
      unless @content
        @metadata_java = Metadata.new
        @content = @tika.parse_to_string(input_stream, @metadata_java).to_s.strip
      end
    end

    def get_input_type
      if File.exists?(@data_source) && File.directory?(@data_source) == false
        :file
      elsif URI(@data_source).is_a?(URI::HTTP) && open(@data_source)
        :http
      else
        raise IOError, "Input (#{@data_source}) is neither file nor http."
      end
    end

    def input_stream
      file? \
          ? FileInputStream.new(java.io.File.new(@data_source)) \
          : URL.new(@data_source).open_stream
    end
  end
end
