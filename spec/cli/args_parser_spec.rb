# frozen_string_literal: true

require 'spec_helper'

require 'rika/cli/args_parser'

describe ArgsParser do
  specify 'returns a hash of options, a target array, and help text' do
    options, targets, help_text = ArgsParser.call([])
    expect(options).to be_a(Hash)
    expect(targets).to be_an(Array)
    expect(help_text).to be_a(String)
  end

  context 'parse_options' do
    RSpec.shared_examples 'sets_options_correctly' do |args, option_key, expected_value|
      specify "correctly sets #{option_key} to #{expected_value} when args are #{args}" do
        options, _, _ = ArgsParser.call(args)
        expect(options[option_key]).to eq(expected_value)
      end
    end

    # Test default option values:
    include_examples('sets_options_correctly', [], :as_array, false)
    include_examples('sets_options_correctly', [], :text, true)
    include_examples('sets_options_correctly', [], :metadata, true)
    include_examples('sets_options_correctly', [], :format, 'at')

    # Test -a as_array option:
    include_examples('sets_options_correctly', %w[-a], :as_array, true)
    include_examples('sets_options_correctly', %w[--as_array], :as_array, true)
    include_examples('sets_options_correctly', %w[-a -a-], :as_array, false)
    include_examples('sets_options_correctly', %w[-a -a-], :as_array, false)
    include_examples('sets_options_correctly', %w[--no-as_array], :as_array, false)

    # Test -f format option:
    include_examples('sets_options_correctly', %w[-fyy], :format, 'yy')
    include_examples('sets_options_correctly', %w[--format yy], :format, 'yy')
    include_examples('sets_options_correctly', %w[-f yy], :format, 'yy')
    include_examples('sets_options_correctly', %w[-f y], :format, 'yy')
    include_examples('sets_options_correctly', %w[-f yj], :format, 'yj')
    include_examples('sets_options_correctly', %w[-f yjJ], :format, 'yj') # Test extra characters after valid format

    # Test -m metadata option:
    include_examples('sets_options_correctly', %w[-m- -m], :metadata, true)
    include_examples('sets_options_correctly', %w[-m- -m+], :metadata, true)
    include_examples('sets_options_correctly', %w[--metadata false --metadata], :metadata, true)
    include_examples('sets_options_correctly', %w[-m -m-], :metadata, false)
    include_examples('sets_options_correctly', %w[-m yes], :metadata, true)
    include_examples('sets_options_correctly', %w[-m no], :metadata, false)
    include_examples('sets_options_correctly', %w[-m true], :metadata, true)
    include_examples('sets_options_correctly', %w[-m false], :metadata, false)
    include_examples('sets_options_correctly', %w[--metadata false], :metadata, false)
    include_examples('sets_options_correctly', %w[--no-metadata], :metadata, false)

    # Test -t text option:
    include_examples('sets_options_correctly', %w[-t], :text, true)
    include_examples('sets_options_correctly', %w[-t -t-], :text, false)
    include_examples('sets_options_correctly', %w[-t yes], :text, true)
    include_examples('sets_options_correctly', %w[-t no], :text, false)
    include_examples('sets_options_correctly', %w[-t true], :text, true)
    include_examples('sets_options_correctly', %w[-t false], :text, false)
    include_examples('sets_options_correctly', %w[--text false], :text, false)
    include_examples('sets_options_correctly', %w[--text false --text], :text, true)
  end
end
