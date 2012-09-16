# encoding: utf-8

require 'spec_helper'

describe Rika::Parser do
  # TODO: add specs for file not found, unknown mimetypes, filestreams and URLs

  describe '#content' do
    it "should return the content in a text file" do
      parser = Rika::Parser.new(file_path("text_file.txt"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end

    it "should return the content in a docx file" do
      parser = Rika::Parser.new(file_path("document.docx"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end

    it "should return the content in a pdf file" do
      parser = Rika::Parser.new(file_path("document.pdf"))
      parser.content.strip.should == "First they ignore you, then they ridicule you, then they fight you, then you win."
    end

    it "should return no content for an image" do
      parser = Rika::Parser.new(file_path("image.jpg"))
      parser.content.should be_empty
    end
  end

  describe '#metadata' do
    # We just test a few of the metadata fields for some common file formats 
    # to make sure the integration with Apache Tika works.
    # Apache Tika already have tests for all file formats it supports.

    it "should return nil if metadata field does not exists" do
      parser = Rika::Parser.new(file_path("text_file.txt"))
      parser.metadata["nonsense"].should be_nil
    end

    it "should return metadata from a text file" do
      parser = Rika::Parser.new(file_path("text_file.txt"))
      parser.metadata["filename"].should == "text_file.txt"
    end

    it "should return metadata from a docx file" do
      parser = Rika::Parser.new(file_path("document.docx"))
      parser.metadata["Page-Count"].should == "1"
    end

    it "should return metadata from a pdf file" do
      parser = Rika::Parser.new(file_path("document.pdf"))
      parser.metadata["title"].should == "A simple title"
    end

    it "should return metadata from an image" do
      parser = Rika::Parser.new(file_path("image.jpg"))
      parser.metadata["Image Height"].should == "72 pixels"
      parser.metadata["Image Width"].should == "72 pixels"
    end
  end
end
