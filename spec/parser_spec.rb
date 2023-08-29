# frozen_string_literal: true

require 'spec_helper'
require 'rika/parser'

describe Rika::Parser do
  context '#parse' do
    let(:parser) { Rika::Parser.new('spec/fixtures/document.pdf') }
    let(:parse_result) { parser.parse }
    let(:metadata) { parse_result.metadata }

    specify 'returns a ParseResult' do
      expect(parse_result).to be_a(Rika::ParseResult)
    end

    specify 'ParseResult contains the expected fields' do
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

    specify 'ParseResult contains the expected content' do
      expect(parse_result.content).to include('Stopping by Woods on a Snowy Evening')
    end

    specify 'ParseResult contains the expected metadata' do
      expect(parse_result.metadata).to include(
        "dc:creator" => "Robert Frost",
        "dc:format" => "application/pdf; version=1.3",
        "dc:title" => "Stopping by Woods on a Snowy Evening",
        "rika:data-source" => "spec/fixtures/document.pdf",
        "rika:language" => "en",
      )
    end

    specify 'ParseResult contains the expected metadata_java' do
      expect(parse_result.metadata_java).to be_a(Java::OrgApacheTikaMetadata::Metadata)
    end

    specify 'ParseResult contains the expected content_type' do
      expect(parse_result.content_type).to eq('application/pdf')
    end

    specify 'ParseResult contains the expected language' do
      expect(parse_result.language).to eq('en')
    end

    specify 'ParseResult contains the expected input_type' do
      expect(parse_result.input_type).to eq(:file)
    end

    specify 'ParseResult contains the expected data_source' do
      expect(parse_result.data_source).to eq('spec/fixtures/document.pdf')
    end

    # specify 'ParseResult contains the expected max_content_length' do
    #   expect(parse_result.max
  end
end