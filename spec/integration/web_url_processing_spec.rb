# frozen_string_literal: true

require 'spec_helper'
require 'rika'
require 'webrick'
require 'net/http'
require 'stringio'

describe 'Web URL Processing', type: :integration do
  # Set up a simple HTTP server for testing
  let(:port) { 50515 }
  let(:fixtures_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../fixtures')) }
  let(:url_base) { "http://#{Socket.gethostname}:#{port}" }
  let(:txt_url) { "#{url_base}/document.txt" }
  let(:pdf_url) { "#{url_base}/document.pdf" }
  let(:docx_url) { "#{url_base}/document.docx" }
  let(:large_url) { "#{url_base}/large.txt" }  # This would be a large text file in fixtures
  let(:redirecting_url) { "#{url_base}/redirect" }
  let(:not_found_url) { "#{url_base}/not_found.txt" }
  let(:server_error_url) { "#{url_base}/server_error" }
  
  # Create a server runner helper that starts a WEBrick server for tests
  def with_server(&block)
    server = nil
    server_thread = Thread.new do
      server = WEBrick::HTTPServer.new(
        Port: port,
        DocumentRoot: fixtures_dir,
        AccessLog: [],
        Logger: WEBrick::Log.new('/dev/null')
      )
      
      # Add a redirect handler
      server.mount_proc('/redirect') do |req, res|
        res.status = 302
        res['Location'] = "#{url_base}/document.txt"
      end
      
      # Add a server error handler
      server.mount_proc('/server_error') do |req, res|
        res.status = 500
        res.body = 'Internal Server Error'
      end
      
      # Add a handler for 404 errors
      server.mount_proc('/not_found.txt') do |req, res|
        res.status = 404
        res.body = 'Not Found'
      end
      
      server.start
    end
    
    # Wait for server to become ready
    sleep 0.1 while server.nil?
    
    begin
      yield
    ensure
      server.shutdown
      server_thread.join(5)  # Give it 5 seconds to shut down
    end
  end
  
  context 'with valid URLs' do
    it 'successfully retrieves and processes text content from a URL' do
      with_server do
        result = Rika.parse(txt_url)
        
        aggregate_failures do
          expect(result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(result.metadata).to include('Content-Type')
          expect(result.input_type).to eq(:http)
          expect(result.http?).to be true
          expect(result.file?).to be false
        end
      end
    end
    
    it 'successfully retrieves and processes PDF content from a URL' do
      with_server do
        result = Rika.parse(pdf_url)
        
        aggregate_failures do
          expect(result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(result.metadata).to include('Content-Type')
          expect(result.metadata).to include('dc:creator' => 'Robert Frost')
        end
      end
    end
    
    it 'successfully retrieves and processes DOCX content from a URL' do
      with_server do
        result = Rika.parse(docx_url)
        
        aggregate_failures do
          expect(result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(result.metadata['Content-Type']).to include('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
        end
      end
    end
    
    it 'successfully processes large files from a URL' do
      with_server do
        result = Rika.parse(large_url)
        
        aggregate_failures do
          # Check that content was extracted
          expect(result.content).not_to be_empty
          expect(result.content.length).to be > 1000  # Should be a large amount of content
          expect(result.metadata).to include('Content-Type')
        end
      end
    end
  end
  
  context 'with content size limitations' do
    it 'respects max_content_length when retrieving from URL' do
      with_server do
        full_result = Rika.parse(txt_url)
        limited_result = Rika.parse(txt_url, max_content_length: 10)
        
        aggregate_failures do
          expect(limited_result.content.length).to be <= 10
          expect(full_result.content.length).to be > limited_result.content.length
          expect(full_result.content).to start_with(limited_result.content)
        end
      end
    end
    
    it 'correctly limits content of large files' do
      with_server do
        # Test with varying content length limits
        result_100 = Rika.parse(large_url, max_content_length: 100)
        result_1000 = Rika.parse(large_url, max_content_length: 1000)
        
        aggregate_failures do
          # Verify content lengths
          expect(result_100.content.length).to be <= 100
          expect(result_1000.content.length).to be <= 1000
          expect(result_1000.content.length).to be > result_100.content.length
          
          # First part of content should be the same
          expect(result_1000.content).to start_with(result_100.content)
        end
      end
    end
  end
  
  context 'with HTTP redirects' do
    it 'follows HTTP redirects correctly' do
      with_server do
        result = Rika.parse(redirecting_url)
        
        aggregate_failures do
          # Should follow redirect to document.txt
          expect(result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(result.metadata).to include('Content-Type')
        end
      end
    end
  end
  
  context 'with HTTP errors' do
    it 'handles 404 Not Found errors gracefully' do
      with_server do
        # Use aggregate_failures here because we have a compound expect
        expect { Rika.parse(not_found_url) }.to raise_error do |error|
          # Just check if the error contains the URL that caused the error
          expect(error.message).to include(not_found_url)
        end
      end
    end
    
    it 'handles 500 Server Error errors gracefully' do
      with_server do
        # Expect an error to be raised
        expect { Rika.parse(server_error_url) }.to raise_error(Java::JavaIo::IOException, /500|Server Error/)
      end
    end
  end
  
  context 'with unavailable servers' do
    it 'handles unavailable servers gracefully' do
      unavailable_server = 'http://non-existent-server-12345.example.com'
      unavailable_file = "#{unavailable_server}/document.pdf"
      
      expect { Rika.parse(unavailable_file) }.to raise_error(Java::JavaNet::UnknownHostException)
    end
  end
  
  context 'with mixed input sources' do
    let(:local_file) { fixture_path('document.txt') }
    
    it 'can process local files and URLs in the same session' do
      with_server do
        local_result = Rika.parse(local_file)
        url_result = Rika.parse(txt_url)
        
        aggregate_failures do
          # Local file checks
          expect(local_result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(local_result.input_type).to eq(:file)
          
          # URL checks
          expect(url_result.content).to include('Stopping by Woods on a Snowy Evening')
          expect(url_result.input_type).to eq(:http)
        end
      end
    end
  end
  
  context 'testing multiple URL formats in sequence' do
    it 'processes different URL types correctly' do
      with_server do
        # Define URLs to test with expected content types
        urls = [
          {url: txt_url, expected_type: 'text/plain', name: 'Text document'},
          {url: pdf_url, expected_type: 'application/pdf', name: 'PDF document'},
          {url: docx_url, expected_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', name: 'DOCX document'},
          {url: large_url, expected_type: 'text/plain', name: 'Large text file'},
          {url: redirecting_url, expected_type: 'text/plain', name: 'Redirecting URL'}
        ]
        
        # Process each URL
        results = {}
        urls.each do |url_info|
          url = url_info[:url]
          name = url_info[:name]
          # Store result for later verification
          results[url] = Rika.parse(url, max_content_length: 1000)
        end
        
        # Verify each result separately
        urls.each do |url_info|
          url = url_info[:url]
          expected_type = url_info[:expected_type]
          name = url_info[:name]
          result = results[url]
          
          aggregate_failures "for #{name}" do
            expect(result.metadata).to include('Content-Type')
            expect(result.content).not_to be_empty
            # Only check for the base content type without charset
            expect(result.metadata['Content-Type']).to include(expected_type.split(';').first)
            expect(result.input_type).to eq(:http)
          end
        end
      end
    end
  end
end 