# frozen_string_literal: true

module Rika

  # Encapsulates all results of parsing a document.
  ParseResult = Struct.new(
    :content,
    :metadata,
    :metadata_java,
    :content_type,
    :language,
    :input_type,
    :data_source,
    :max_content_length,
    keyword_init: true
  ) do
    # @return [Boolean] true if, and only if, input is a file
    def file?
      input_type == :file
    end

    # @return [Boolean] true if, and only if, input is HTTP
    def http?
      input_type == :http
    end

    # @return [Hash] content and metadata of ParseResult instance as hash
    def content_and_metadata_hash
      { content: content, metadata: metadata }
    end
  end
end
