# frozen_string_literal: true

require 'spec_helper'
require 'rika/parser'
require 'rika/parse_result'

describe Rika::Parser do
  context 'when initialized with a content string and metadata' do
    let(:content) { 'Magnifique' }
    let(:metadata) { { 'author' => 'John Doe' } }
    let(:result) { Rika::ParseResult.new(content: content, metadata: metadata) }

    specify '#content_and_metadata_hash returns a hash with content and metadata' do
      expect(result.content_and_metadata_hash).to eq({ content: content, metadata: metadata })
    end
  end

  describe '#parse' do
    let(:parser) { described_class.new('spec/fixtures/document.pdf') }
    let(:parse_result) { parser.parse }
    let(:metadata) { parse_result.metadata }

    specify 'returns an instance of ParseResult' do
      expect(parse_result).to be_a(Rika::ParseResult)
    end

    specify 'returns a ParseResult with the expected access methods' do
      expect(parse_result).to respond_to(
        :content,
        :metadata,
        :metadata_java,
        :content_type,
        :language,
        :input_type,
        :data_source,
        :max_content_length
      )
    end

    specify 'returns a ParseResult with the expected content' do
      expect(parse_result.content).to include('Stopping by Woods on a Snowy Evening')
    end

    specify 'returns a ParseResult with the expected metadata' do
      expect(parse_result.metadata).to include(
        'dc:creator' => 'Robert Frost',
        'dc:format' => 'application/pdf; version=1.3',
        'dc:title' => 'Stopping by Woods on a Snowy Evening',
        'rika:data-source' => 'spec/fixtures/document.pdf',
        'rika:language' => 'en'
      )
    end

    specify 'returns a ParseResult with the expected metadata_java' do
      expect(parse_result.metadata_java).to be_a(Java::OrgApacheTikaMetadata::Metadata)
    end

    specify 'returns a ParseResult with the expected content_type' do
      expect(parse_result.content_type).to eq('application/pdf')
    end

    specify 'returns a ParseResult with the expected language' do
      expect(parse_result.language).to eq('en')
    end

    specify 'returns a ParseResult with the expected input_type' do
      expect(parse_result.input_type).to eq(:file)
    end

    specify 'returns a ParseResult with the expected data_source' do
      expect(parse_result.data_source).to eq('spec/fixtures/document.pdf')
    end

    describe 'metadata key sorting' do
      RSpec.shared_examples('metadata key sorting') do |caption, key_sort|
        specify "Metadata keys are #{caption} case insensitively when key_sort is #{key_sort}" do
          parser = described_class.new('spec/fixtures/document.pdf', key_sort: key_sort)
          keys = parser.parse.metadata.keys
          expect(keys == keys.sort_by(&:downcase)).to eq(key_sort)
          expect(keys).not_to eq(keys.map(&:downcase)) # Above test only valid if both upper and lower case occur.
        end
      end

      include_examples 'metadata key sorting', 'sorted', true
      include_examples 'metadata key sorting', 'not sorted', false
    end

    specify 'returns a ParseResult with the expected max_content_length' do
      expect(parse_result.max_content_length).to eq(-1)
    end
  end
end
