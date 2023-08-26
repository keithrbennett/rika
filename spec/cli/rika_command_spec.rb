# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/rika_command'

describe RikaCommand do

  before do
    @original_stdout = $stdout
    $stdout = StringIO.new
  end

  after do
    $stdout = @original_stdout
  end

  describe '#run' do
    it 'should run' do
      expect { RikaCommand.new.run(__FILE__) }.to_not raise_error
    end
  end

  describe '#parse_command_line' do
    RSpec.shared_examples 'test_arg_parsing' do |args, option_key, expected_value|
      specify "correctly sets #{option_key} to #{expected_value} when args are #{args}" do
        rika_command = RikaCommand.new
        options = rika_command.send(:parse_command_line, args)
        expect(options[option_key]).to eq(expected_value)
      end
    end

    # Test default option values:
    include_examples('test_arg_parsing', [], :as_array, false)
    include_examples('test_arg_parsing', [], :text, true)
    include_examples('test_arg_parsing', [], :metadata, true)
    include_examples('test_arg_parsing', [], :format, 'at')

    # Test -a as_array option:
    include_examples('test_arg_parsing', %w[-a], :as_array, true)
    include_examples('test_arg_parsing', %w[--as_array], :as_array, true)
    include_examples('test_arg_parsing', %w[-a -a-], :as_array, false)
    include_examples('test_arg_parsing', %w[-a -a-], :as_array, false)
    include_examples('test_arg_parsing', %w[--no-as_array], :as_array, false)

    # Test -f format option:
    include_examples('test_arg_parsing', %w[-fyy], :format, 'yy')
    include_examples('test_arg_parsing', %w[--format yy], :format, 'yy')
    include_examples('test_arg_parsing', %w[-f yy], :format, 'yy')
    include_examples('test_arg_parsing', %w[-f y], :format, 'yy')
    include_examples('test_arg_parsing', %w[-f yj], :format, 'yj')
    include_examples('test_arg_parsing', %w[-f yjJ], :format, 'yj') # Test extra characters after valid format

    # Test -m metadata option:
    include_examples('test_arg_parsing', %w[-m- -m], :metadata, true)
    include_examples('test_arg_parsing', %w[--metadata false --metadata], :metadata, true)
    include_examples('test_arg_parsing', %w[-m -m-], :metadata, false)
    include_examples('test_arg_parsing', %w[-m yes], :metadata, true)
    include_examples('test_arg_parsing', %w[-m no], :metadata, false)
    include_examples('test_arg_parsing', %w[-m true], :metadata, true)
    include_examples('test_arg_parsing', %w[-m false], :metadata, false)
    include_examples('test_arg_parsing', %w[--metadata false], :metadata, false)
    include_examples('test_arg_parsing', %w[--no-metadata], :metadata, false)

    # Test -t text option:
    include_examples('test_arg_parsing', %w[-t], :text, true)
    include_examples('test_arg_parsing', %w[-t -t-], :text, false)
    include_examples('test_arg_parsing', %w[-t yes], :text, true)
    include_examples('test_arg_parsing', %w[-t no], :text, false)
    include_examples('test_arg_parsing', %w[-t true], :text, true)
    include_examples('test_arg_parsing', %w[-t false], :text, false)
    include_examples('test_arg_parsing', %w[--text false], :text, false)
    include_examples('test_arg_parsing', %w[--text false --text], :text, true)
  end
end

