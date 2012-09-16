# encoding: utf-8

require 'spec_helper'

describe Rika::Parser do
  # TODO: add specs for file not found, unknown mimetypes, filestreams and URLs

  describe '#content' do
    it "should return the content in a text file" do
      parser = Rika::Parser.new(file_path("text_file.txt"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end

    it "should return the content in a doc file" do
      parser = Rika::Parser.new(file_path("document.doc"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end

    it "should return the content in a pdf file" do
      parser = Rika::Parser.new(file_path("document.doc"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end

    it "should return no content for an image" do
      parser = Rika::Parser.new(file_path("image.jpg"))
      parser.content.should be_empty
    end
  end
end
