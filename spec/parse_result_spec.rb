# frozen_string_literal: true

require 'spec_helper'
require 'rika/parse_result'

describe Rika::ParseResult do

  context 'when initialized' do
    specify 'contains the necessary fields' do
      expect(Rika::ParseResult.new).to respond_to(
        :content,
        :metadata,
        :metadata_java,
        :media_type,
        :language,
        :input_type,
        :data_source,
        :max_content_length
      )
    end
  end

  context 'when initialized with a content string and metadata' do
    let(:content) { 'Magnifique' }
    let(:metadata) { { 'author' => 'John Doe' } }
    let(:result) { Rika::ParseResult.new(content: content, metadata: metadata) }

    specify 'contains the language' do
      expect(result.language).to eq('fr')
    end

    specify '#content_and_metadata_hash returns a hash with content and metadata' do
      expect(result.content_and_metadata_hash).to eq({ content: content, metadata: metadata })
    end
  end
end
