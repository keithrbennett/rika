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

  describe '#file?' do
    specify 'returns true if input_type is :file' do
      expect(described_class.new(input_type: :file).file?).to be true
    end

    specify 'returns false if input_type is not :file' do
      expect(described_class.new.file?).to be false
    end
  end

  describe '#http?' do
    specify 'returns true if input_type is :http' do
      expect(described_class.new(input_type: :http).http?).to be true
    end

    specify 'returns false if input_type is not :http' do
      expect(described_class.new.http?).to be false
    end
  end
end
