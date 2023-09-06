# frozen_string_literal: true

require 'spec_helper'
require 'webrick'

describe Rika::Parser do
  port = 50515

  let(:text_parse_result)    { Rika.parse(fixture_path('document.txt')) }
  let(:docx_parse_result)    { Rika.parse(fixture_path('document.docx')) }
  let(:doc_parse_result)     { Rika.parse(fixture_path('document.doc'))  }
  let(:pdf_parse_result)     { Rika.parse(fixture_path('document.pdf'))  }
  let(:image_parse_result)   { Rika.parse(fixture_path('image.jpg'))     }
  let(:unknown_parse_result) { Rika.parse(fixture_path('unknown.bin'))   }
  let(:fixtures_dir)         { File.expand_path(File.join(File.dirname(__FILE__), '../fixtures')) }
  let(:quote_first_line) { 'Stopping by Woods on a Snowy Evening' }
  let(:url) { "http://#{Socket.gethostname}:#{port}" }
  let(:sample_pdf_filespec) { fixture_path('document.pdf') }
  let(:first_line) { ->(string) { string.split("\n").first.strip } }

  # returns a lambda that, when passed an action, will wrap it in an HTTP server
  let(:server_runner) do
    ->(action) do
      server = nil
      server_thread = Thread.new do
        server = WEBrick::HTTPServer.new(
          Port:         port,
          DocumentRoot: fixtures_dir,
          AccessLog:    [],
          Logger:       WEBrick::Log.new('/dev/null')
        )
        server.start
      end

      # Wait for server to become ready on its new thread
      sleep 0.01 while server.nil?
      begin
        action.call
      ensure
        server.shutdown
        server_thread.exit
      end
    end
  end

  it 'raises an error if the file does not exist' do
    expect { Rika.parse(fixture_path('nonexistent_file.txt')) }.to raise_error(IOError)
  end

  it 'raises an error if the URL does not exist' do
    unavailable_server = 'http://k6075sd0dfkr8nvfw0zvwfwckucf2aba.com'
    unavailable_file_on_web = File.join(unavailable_server, 'x.pdf')
    expect { Rika.parse(unavailable_file_on_web) }.to raise_error(Java::JavaNet::UnknownHostException)
  end

  it 'detects a file type without a file extension' do
    parse_result = Rika.parse(fixture_path('image_jpg_without_extension'))
    expect(parse_result.metadata['Content-Type']).to eq('image/jpeg')
  end

  describe '#content' do
    it 'returns the content in a text file' do
      expect(first_line.(text_parse_result.content)).to eq(quote_first_line)
    end

    it 'returns the content in a docx file' do
      expect(first_line.(docx_parse_result.content)).to eq(quote_first_line)
    end

    it 'returns the content in a pdf file' do
      # For some reason, the generated PDF file has a newline at the beginning
      # and trailing spaces on the lines, so we use the second line, and
      # use `include` to do the text match.
      expect(pdf_parse_result.content.lines[1]).to include(quote_first_line)
    end

    it 'returns no content for an image' do
      expect(image_parse_result.content).to be_empty
    end

    it 'only returns max content length from a text file' do
      expect(Rika.parse(fixture_path('document.txt'), max_content_length: 8).content).to eq('Stopping')
    end

    it 'only returns max content length from a PDF' do
      expect(Rika.parse(fixture_path('document.pdf'), max_content_length: 9).content).to eq("\nStopping")
    end

    it 'only returns max content length for file over http' do
      server_runner.call(-> do
        content = Rika.parse(File.join(url, 'document.txt'), max_content_length: 8).content
        expect(content).to eq('Stopping')
      end)
    end

    it 'returns the content from a file over http' do
      content = server_runner.call(-> do
        Rika.parse(File.join(url, 'document.txt')).content
      end)
      expect(first_line.(content)).to eq(quote_first_line)
    end

    it 'return empty string for unknown file' do
      expect(unknown_parse_result.content).to be_empty
    end
  end

  # We just test a few of the metadata fields for some common file formats
  # to make sure the integration with Apache Tika works. Apache Tika already
  # have tests for all file formats it supports so we won't retest that
  describe '#metadata' do
    it 'returns nil if metadata field does not exist' do
      expect(text_parse_result.metadata['nonsense']).to be_nil
    end

    it 'returns metadata from a docx file' do
      expect(docx_parse_result.metadata['meta:page-count']).to eq('1')
    end

    it 'returns metadata from a pdf file' do
      expect(pdf_parse_result.metadata['pdf:docinfo:creator']).to eq('Robert Frost')
    end

    it 'returns metadata from a file over http' do
      server_runner.call(-> do
        parser = Rika.parse(File.join(url, 'document.pdf'))
        expect(parser.metadata['pdf:docinfo:creator']).to eq('Robert Frost')
      end)
    end

    it 'returns metadata from an image' do
      expect(image_parse_result.metadata['Image Height']).to eq('72 pixels')
      expect(image_parse_result.metadata['Image Width']).to  eq('72 pixels')
    end
  end

  describe '#content_type' do
    it 'returns application/pdf for a pdf file' do
      expect(pdf_parse_result.content_type).to eq('application/pdf')
    end

    it 'returns text/plain for a txt file' do
      expect(text_parse_result.content_type).to eq('text/plain; charset=UTF-8')
    end

    it 'returns application/pdf for a pdf over http' do
      server_runner.call(-> do
        parse_result = Rika.parse(File.join(url, 'document.pdf'))
        expect(parse_result.content_type).to eq('application/pdf')
      end)
    end

    it 'returns application/octet-stream for unknown file' do
      expect(unknown_parse_result.content_type).to eq('application/octet-stream')
    end

    it 'returns msword for a doc file' do
      # There seem to be two permissible content types for a doc file.
      expect(%w{application/msword application/x-tika-msoffice}.include?(doc_parse_result.content_type)).to be true
    end

    it 'returns wordprocessingml for a docx file' do
      expect(docx_parse_result.content_type).to eq(
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      )
    end
  end

  describe '#language' do
    it 'returns the language of the content' do
      %w(en de fr ru es).each do |lang|
        parse_result = Rika.parse(fixture_path("#{lang}.txt"))
        expect(parse_result.language).to eq(lang)
      end
    end
  end

  it 'returns valid content using Rika.parse_content' do
    content = Rika.parse_content(sample_pdf_filespec)
    expect(content).to be_a(String)
    expect(content).not_to be_empty
  end

  it 'returns valid metadata using Rika.parse_metadata' do
    metadata = Rika.parse_metadata(sample_pdf_filespec)
    expect(metadata).to be_a(Hash)
    expect(metadata).not_to be_empty
  end

  it 'returns valid content and metadata using Rika.parse_content_and_metadata' do
    content, metadata = Rika.parse_content_and_metadata(sample_pdf_filespec)
    expect(content).to be_a(String)
    expect(content).not_to be_empty
    expect(metadata).to be_a(Hash)
    expect(metadata).not_to be_empty
  end

  specify 'both means of getting both content and metadata return the same values' do
    content1, metadata1 = Rika.parse_content_and_metadata(sample_pdf_filespec)

    h = Rika.parse_content_and_metadata_as_hash(sample_pdf_filespec)
    content2  = h[:content]
    metadata2 = h[:metadata]

    expect(content1).to eq(content2)
    expect(metadata1).to eq(metadata2)
  end

  specify 'getting content and metadata individually and together return the same values' do
    content1, metadata1 = Rika.parse_content_and_metadata(sample_pdf_filespec)
    content2             = Rika.parse_content(sample_pdf_filespec)
    metadata2            = Rika.parse_metadata(sample_pdf_filespec)

    expect(content1).to eq(content2)
    expect(metadata1).to eq(metadata2)
  end
end
