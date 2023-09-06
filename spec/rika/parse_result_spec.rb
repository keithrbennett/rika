# frozen_string_literal: true

require 'spec_helper'
require 'rika/parse_result'

describe Rika::ParseResult do
  context 'when initialized' do
    specify 'contains the necessary fields' do
      expect(described_class.new).to respond_to(
        :content,
        :text, # alias for content
        :metadata,
        :metadata_java,
        :content_type,
        :language,
        :input_type,
        :data_source,
        :max_content_length
      )
    end
  end
end
