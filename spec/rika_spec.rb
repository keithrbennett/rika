# encoding: utf-8

require 'spec_helper'

describe Rika::Parser do

  describe '#content' do
    it "should return the content in a file" do

      parser = Rika::Parser.new(file_path("text_file.txt"))
      parser.content.should == "First they ignore you, then they ridicule you, then they fight you, then you win.\n"
    end
  end
end
