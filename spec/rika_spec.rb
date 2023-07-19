# encoding: utf-8

require 'spec_helper'
require 'webrick'

include WEBrick

describe Rika::Parser do

    let (:txt_parser)       { Rika::Parser.new(file_path('text_file.txt')) }
    let (:docx_parser)      { Rika::Parser.new(file_path('document.docx')) }
    let (:doc_parser)       { Rika::Parser.new(file_path('document.doc'))  }
    let (:pdf_parser)       { Rika::Parser.new(file_path('document.pdf'))  }
    let (:image_parser)     { Rika::Parser.new(file_path('image.jpg'))     }
    let (:unknown_parser)   { Rika::Parser.new(file_path('unknown.bin'))   }
    let (:dir)              { File.expand_path(File.join(File.dirname(__FILE__), 'fixtures')) }
    let (:quote_first_line) { 'Stopping by Woods on a Snowy Evening' }

    port = 50515
    let (:url) { "http://#{Socket.gethostname}:#{port}" }

    let (:sample_pdf_filespec) { file_path('document.pdf') }

    let(:first_line) { ->(string) { string.split("\n").first.strip } }

    let(:server_runner) do
      # returns a lambda that, when passed an action, will wrap it in an HTTP server
      ->(action) do
        server = nil
        server_thread = Thread.new do
          server = HTTPServer.new(
              Port:         port,
              DocumentRoot: dir,
              AccessLog:    [],
              Logger:       WEBrick::Log::new('/dev/null')
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


  it 'should raise error if file does not exist' do
    expect(-> { Rika::Parser.new(file_path('nonexistent_file.txt')) }).to raise_error(IOError)
  end

  it 'should raise error if URL does not exist' do
    unavailable_server = 'http://k6075sd0dfkr8nvfw0zvwfwckucf2aba.com'
    unavailable_file_on_web = File.join(unavailable_server, 'x.pdf')
    expect(-> { Rika::Parser.new(unavailable_file_on_web) }).to raise_error(SocketError)
  end

  it 'should detect file type without a file extension' do
    parser = Rika::Parser.new(file_path('text_file_without_extension'))
    expect(parser.metadata['Content-Type']).to eq('text/plain; charset=UTF-8')
  end

  describe '#content' do
    it 'should return the content in a text file' do
      expect(first_line.(txt_parser.content)).to eq(quote_first_line)
    end

    it 'should return the content in a docx file' do
      expect(first_line.(docx_parser.content)).to eq(quote_first_line)
    end

    it 'should return the content in a pdf file' do
      expect(first_line.(pdf_parser.content)).to eq(quote_first_line)
    end

    it 'should return no content for an image' do
      expect(image_parser.metadata.keys).to_not be_empty
    end

    it 'should only return max content length' do
      expect(Rika::Parser.new(file_path('text_file.txt'), 9).content).to eq('Stopping')
    end

    it 'should only return max content length for file over http', focus: true do
      server_runner.call( -> do
        expect(Rika::Parser.new(File.join(url, 'document.pdf'), 9).content).to eq('Stopping')
      end)
    end

    it 'should return the content from a file over http' do
      server_runner.call( -> do
        content = Rika::Parser.new(File.join(url, 'document.pdf')).content
        expect(first_line.(content)).to eq(quote_first_line)
      end)
    end

    it 'should return empty string for unknown file' do
      expect(unknown_parser.content).to be_empty
    end
  end

  # We just test a few of the metadata fields for some common file formats
  # to make sure the integration with Apache Tika works. Apache Tika already
  # have tests for all file formats it supports so we won't retest that
  describe '#metadata' do
    it 'should return nil if metadata field does not exist' do
      expect(txt_parser.metadata['nonsense']).to be_nil
    end

    it 'should return metadata from a docx file' do
      expect(docx_parser.metadata['meta:page-count']).to eq('1')
    end

    it 'should return metadata from a pdf file' do
      expect(pdf_parser.metadata['pdf:docinfo:creator']).to eq('Robert Frost')
    end

    it 'should return metadata from a file over http', focus: true do
      server_runner.call( -> do
        parser = Rika::Parser.new(File.join(url, 'document.pdf'))
        expect(parser.metadata['pdf:docinfo:creator']).to eq('Robert Frost')
      end)
    end

    it 'should return metadata from an image' do
      expect(image_parser.metadata['Image Height']).to eq('72 pixels')
      expect(image_parser.metadata['Image Width']).to  eq('72 pixels')
    end
  end

  describe '#available_metadata' do
    it 'should return available metadata fields' do
      expect(txt_parser.available_metadata).to_not be_empty
    end

    it 'should be an array' do
      expect(txt_parser.available_metadata).to be_an(Array)
    end
  end

  describe '#metadata_exists?' do
    it 'should return false if metadata does not exist' do
      expect(txt_parser.metadata_exists?('dc:title')).to be false
    end

    it 'should return true if metadata exist' do
      expect(docx_parser.metadata_exists?('dc:title')).to be true
    end
  end

  describe '#media_type' do
    it 'should return application/pdf for a pdf file' do
      expect(pdf_parser.media_type).to eq('application/pdf')
    end

    it 'should return text/plain for a txt file' do
      expect(txt_parser.media_type).to eq('text/plain')
    end

    it 'should return application/pdf for a pdf over http' do
      server_runner.call( -> do
        parser = Rika::Parser.new(File.join(url, 'document.pdf'))
        expect(parser.media_type).to eq('application/pdf')
      end)
    end

    it 'should return application/octet-stream for unknown file' do
      expect(unknown_parser.media_type).to eq('application/octet-stream')
    end

    it 'should return msword for a doc file' do
      expect(doc_parser.media_type).to eq('application/msword')
    end

    it 'should return wordprocessingml for a docx file' do
      expect(docx_parser.media_type).to eq('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    end
  end

  describe '#language' do
    it 'should return the language of the content' do
      %w(en de fr ru es).each do |lang|
        txt = Rika::Parser.new(file_path("#{lang}.txt"))
        expect(txt.language).to eq(lang)
      end
    end
  end

  it 'should return valid content using Rika.parse_content' do
    content = Rika.parse_content(sample_pdf_filespec)
    expect(content).to be_a(String)
    expect(content).to_not be_empty
  end

  it 'should return valid metadata using Rika.parse_metadata' do
    metadata = Rika.parse_metadata(sample_pdf_filespec)
    expect(metadata).to be_a(Hash)
    expect(metadata).to_not be_empty
  end

  it 'should return valid content and metadata using Rika.parse_content_and_metadata' do
    content, metadata = Rika.parse_content_and_metadata(sample_pdf_filespec)
    expect(content).to be_a(String)
    expect(content).to_not be_empty
    expect(metadata).to be_a(Hash)
    expect(metadata).to_not be_empty
  end

  specify 'both means of getting both content and metadata should return the same values' do
    content_1, metadata_1 = Rika.parse_content_and_metadata(sample_pdf_filespec)

    h = Rika.parse_content_and_metadata_as_hash(sample_pdf_filespec)
    content_2  = h[:content]
    metadata_2 = h[:metadata]

    expect(content_1).to eq(content_2)
    expect(metadata_1).to eq(metadata_2)
  end

  specify 'getting content and metadata individually and together should return the same values' do
    content_1, metadata_1 = Rika.parse_content_and_metadata(sample_pdf_filespec, -1)
    content_2             = Rika.parse_content(sample_pdf_filespec)
    metadata_2            = Rika.parse_metadata(sample_pdf_filespec, -1)

    expect(content_1).to eq(content_2)
    expect(metadata_1).to eq(metadata_2)
  end
end
