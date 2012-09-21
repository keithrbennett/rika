# encoding: utf-8

require 'spec_helper'
require 'webrick'

include WEBrick
 
describe Rika::Parser do 
  before(:all) do
    @txt_parser = Rika::Parser.new(file_path("text_file.txt"))
    @docx_parser = Rika::Parser.new(file_path("document.docx"))
    @pdf_parser = Rika::Parser.new(file_path("document.pdf"))
    @image_parser = Rika::Parser.new(file_path("image.jpg"))
    @dir = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))  
    port = 50505
    @url = "http://#{Socket.gethostname}:#{port}"
    
    @t1 = Thread.new do
      @server = HTTPServer.new(:Port => port, :DocumentRoot => @dir, 
      :AccessLog => [], :Logger => WEBrick::Log::new("/dev/null", 7))  
      @server.start
    end
  end

  after(:all) do
    @t1.exit
  end

  it "should raise error if file does not exists" do
    lambda { Rika::Parser.new(file_path("nonsense.txt")) }.should raise_error(IOError, "File does not exist or can't be reached.")
  end

  it "should raise error if URL does not exists" do
    lambda { Rika::Parser.new("http://nonsense.com/whatever.pdf") }.should raise_error(IOError, "File does not exist or can't be reached.")
  end

  it "should detect file type without a file extension" do
    parser = Rika::Parser.new(file_path("text_file_without_extension"))
    parser.metadata["Content-Type"].should == "text/plain; charset=ISO-8859-1"
  end

  describe '#content' do
    it "should return the content in a text file" do
      @txt_parser.content.strip.should == "First they ignore you, then they ridicule you, then they fight you, then you win."
    end

    it "should return the content in a docx file" do
      @docx_parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win."
    end

    it "should return the content in a pdf file" do 
      @pdf_parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win."
    end

    it "should return no content for an image" do
      @image_parser.content.should be_empty
    end

    it "should only return max content length" do
      parser = Rika::Parser.new(file_path("text_file.txt"), 5)
      parser.content.should == "First"
    end

    it "should be possible to read files over 100k by default" do
      parser = Rika::Parser.new(file_path("over_100k_file.txt"))
      parser.content.length.should == 101_761
    end

    it "should return the content from a file over http" do
      parser = Rika::Parser.new(@url + "/document.pdf")
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win."   
    end
  end

  # We just test a few of the metadata fields for some common file formats 
  # to make sure the integration with Apache Tika works. Apache Tika already 
  # have tests for all file formats it supports so we won't retest that
  describe '#metadata' do
    it "should return nil if metadata field does not exists" do
      @txt_parser.metadata["nonsense"].should be_nil
    end

    it "should return metadata from a text file" do
      @txt_parser.metadata["filename"].should == "text_file.txt"
    end

    it "should return metadata from a docx file" do
      @docx_parser.metadata["Page-Count"].should == "1"
    end

    it "should return metadata from a pdf file" do
      @pdf_parser.metadata["title"].should == "A simple title"
    end

    it "should return metadata from a file over http" do
      @pdf_parser.metadata["title"].should == "A simple title"
    end

    it "should return metadata from an image" do
      @image_parser.metadata["Image Height"].should == "72 pixels"
      @image_parser.metadata["Image Width"].should == "72 pixels"
    end
  end

  describe '#available_metadata' do
    it "should return available metadata fields" do
      @txt_parser.available_metadata.should_not be_empty
    end

    it "should be an array" do
      @txt_parser.available_metadata.is_a?(Array).should == true
    end
  end

  describe '#metadata_exists?' do
    it "should return false if metadata does not exists" do
      @txt_parser.metadata_exists?("title").should == false
    end

    it "should return true if metadata exists" do
      @docx_parser.metadata_exists?("title").should == true
    end
  end
end