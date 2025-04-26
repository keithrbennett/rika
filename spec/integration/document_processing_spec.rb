# frozen_string_literal: true

require 'spec_helper'
require 'rika'
require 'tempfile'
require 'fileutils'

describe 'Document Processing Pipeline', type: :integration do
  let(:txt_file) { fixture_path('document.txt') }
  let(:pdf_file) { fixture_path('document.pdf') }
  let(:docx_file) { fixture_path('document.docx') }
  let(:image_file) { fixture_path('image.jpg') }
  let(:large_file) { fixture_path('large.txt') }
  let(:quote_first_line) { 'Stopping by Woods on a Snowy Evening' }
  
  context 'processing different file formats through complete pipeline' do
    it 'correctly processes a text file from start to finish' do
      result = Rika.parse(txt_file)
      
      aggregate_failures do
        expect(result.content.strip.split("\n").first).to eq(quote_first_line)
        expect(result.metadata).to include('Content-Type')
        expect(result.language).to eq('en')
        expect(result.input_type).to eq(:file)
        expect(result.file?).to be true
      end
    end
    
    it 'correctly processes a PDF file from start to finish' do
      result = Rika.parse(pdf_file)
      
      aggregate_failures do
        # PDFs often have a newline at the beginning
        expect(result.content.strip.split("\n").first.strip).to eq(quote_first_line)
        expect(result.metadata).to include('Content-Type' => 'application/pdf')
        expect(result.metadata).to include('dc:creator' => 'Robert Frost')
        expect(result.language).to eq('en')
      end
    end
    
    it 'correctly processes a DOCX file from start to finish' do
      result = Rika.parse(docx_file)
      
      aggregate_failures do
        expect(result.content.strip.split("\n").first).to eq(quote_first_line)
        expect(result.metadata).to include('Content-Type')
        expect(result.language).to eq('en')
      end
    end
    
    it 'correctly processes an image file from start to finish' do
      result = Rika.parse(image_file)
      
      # Images may not have textual content
      expect(result.metadata).to include('Content-Type' => 'image/jpeg')
    end
    
    it 'correctly processes a large file from start to finish' do
      result = Rika.parse(large_file)
      
      aggregate_failures do
        # Check that content was extracted
        expect(result.content).not_to be_empty
        expect(result.content.length).to be > 1000  # Should be a large amount of content
        # The content type may vary based on detected encoding
        expect(result.metadata).to include('Content-Type')
      end
    end
  end
  
  context 'processing files with non-ASCII characters' do
    # Using fixtures with non-ASCII content
    let(:non_ascii_file) { fixture_path('ru.txt') }
    let(:expected_language) { 'ru' }
    
    it 'correctly processes and detects language with non-ASCII characters' do
      result = Rika.parse(non_ascii_file)
      
      aggregate_failures do
        expect(result.language).to eq(expected_language)
        expect(result.content).not_to be_empty
        expect(result.metadata).to include('Content-Type')
      end
    end
  end
  
  context 'processing different parts of the same file' do
    it 'correctly extracts partial content based on max_content_length' do
      # Test with different max_content_length values
      full_result = Rika.parse(txt_file)
      partial_result_10 = Rika.parse(txt_file, max_content_length: 10)
      partial_result_50 = Rika.parse(txt_file, max_content_length: 50)
      
      aggregate_failures do
        # Verify correct truncation
        expect(partial_result_10.content.length).to be <= 10
        expect(partial_result_50.content.length).to be <= 50
        expect(full_result.content.length).to be > 50
        
        # Content should be the beginning part of the full content
        expect(full_result.content).to start_with(partial_result_10.content)
        expect(full_result.content).to start_with(partial_result_50.content)
      end
    end
  end
  
  context 'metadata consistency across formats' do
    it 'provides consistent metadata fields across different file formats' do
      txt_result = Rika.parse(txt_file)
      pdf_result = Rika.parse(pdf_file)
      docx_result = Rika.parse(docx_file)
      
      # Test each file individually for better error reporting
      {
        txt_file => txt_result, 
        pdf_file => pdf_result, 
        docx_file => docx_result
      }.each do |file, result|
        aggregate_failures "for #{File.basename(file)}" do
          expect(result.metadata).to include('Content-Type')
          expect(result.metadata).to include('rika:language')
          expect(result.metadata).to include('rika:data-source')
        end
      end
    end
  end
  
  context 'memory management with large files' do
    it 'processes a large file with limited content length without memory issues' do
      # Process with limited content length (should be efficient with memory)
      result = Rika.parse(large_file, max_content_length: 100)
      
      aggregate_failures do
        # Verify content is limited correctly
        expect(result.content.length).to be <= 100
        expect(result.metadata).to include('Content-Type')
      end
    end
    
    it 'processes a large file multiple times without memory leaks' do
      # Attempt to process the same large file multiple times
      # This is a basic test to ensure no obvious memory leaks
      5.times do |i|
        # Process with different max_content_length each time
        content_limit = 100 + (i * 100)
        result = Rika.parse(large_file, max_content_length: content_limit)
        
        # Verify each result
        aggregate_failures "for iteration #{i+1}" do
          expect(result.content.length).to be <= content_limit
          expect(result.metadata).to include('Content-Type')
        end
      end
      
      # If we reach here without out-of-memory errors, the test passes
    end
  end
  
  context 'sequential processing of multiple files' do
    it 'correctly processes multiple files in sequence' do
      files = [
        {path: txt_file, expected_type: 'text/plain'},
        {path: pdf_file, expected_type: 'application/pdf'},
        {path: docx_file, expected_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'},
        {path: large_file, expected_type: 'text/plain'}
      ]
      
      # Process each file and store the results
      results = {}
      files.each do |file_info|
        file_path = file_info[:path]
        # Use basename for clearer test output
        file_name = File.basename(file_path)
        results[file_name] = Rika.parse(file_path, max_content_length: 1000)
      end
      
      # Verify each result individually for better error reporting
      files.each do |file_info|
        file_path = file_info[:path]
        file_name = File.basename(file_path)
        expected_type = file_info[:expected_type]
        result = results[file_name]
        
        aggregate_failures "for #{file_name}" do
          expect(result.metadata).to include('Content-Type')
          expect(result.content).not_to be_empty
          # The exact content type might include encoding information
          expect(result.metadata['Content-Type']).to include(expected_type.split(';').first)
        end
      end
    end
  end
end 