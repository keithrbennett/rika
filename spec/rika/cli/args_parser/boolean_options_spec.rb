# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/args_parser'

describe 'ArgsParser Boolean Options' do
  # Temporarily capture and suppress stdout to prevent debug output during tests
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  # Define all boolean options with their default values and flag letter
  BOOLEAN_OPTIONS = [
    { key: :metadata, flag: 'm', default: true  },
    { key: :text,     flag: 't', default: true  },
    { key: :key_sort, flag: 'k', default: true  },
    { key: :source,   flag: 's', default: true  },
    { key: :as_array, flag: 'a', default: false },
  ].freeze

  # Define formats for all the different ways to specify boolean values
  # (option name, option args, expected value)
  POSITIVE_FORMATS = [
    ['flag only',            ['-%s'],         true],
    ['flag with +',          ['-%s+'],        true],
    ['flag with "yes"',      ['-%s', 'yes'],  true],
    ['flag with "true"',     ['-%s', 'true'], true],
    ['long form',            ['--%F'],        true],
    ['long form with =true', ['--%F=true'],   true]
  ].freeze

  NEGATIVE_FORMATS = [
    ['flag with -',           ['-%s-'],         false],
    ['flag with "no"',        ['-%s', 'no'],    false],
    ['flag with "false"',     ['-%s', 'false'], false],
    ['long form with no-',    ['--no-%F'],      false],
    ['long form with =false', ['--%F=false'],   false]
  ].freeze

  # Shared example for testing a boolean option with positive formats
  shared_examples 'handles positive formats' do |option_key, option_flag, long_name = nil|
    POSITIVE_FORMATS.each do |desc, format, expected_value|
      it "correctly sets #{option_key} to #{expected_value} with #{desc}" do
        # Use the long_name if available for long form options, otherwise use the flag
        long = long_name || option_flag
        args = format.map { |f| f.gsub('%s', option_flag).gsub('%F', long) }
        options, = ArgsParser.call(args)
        expect(options[option_key]).to eq(expected_value)
      end
    end
  end

  # Shared example for testing a boolean option with negative formats
  shared_examples 'handles negative formats' do |option_key, option_flag, long_name = nil|
    NEGATIVE_FORMATS.each do |desc, format, expected_value|
      it "correctly sets #{option_key} to #{expected_value} with #{desc}" do
        # Use the long_name if available for long form options, otherwise use the flag
        long = long_name || option_flag
        args = format.map { |f| f.gsub('%s', option_flag).gsub('%F', long) }
        options, = ArgsParser.call(args)
        expect(options[option_key]).to eq(expected_value)
      end
    end
  end

  # Shared example for testing default values
  shared_examples 'respects default value' do |option_key, default_value|
    it "uses default value of #{default_value} when option not specified" do
      options, = ArgsParser.call([])
      expect(options[option_key]).to eq(default_value)
    end
  end

  # Shared example for testing option chaining/overriding
  shared_examples 'option chaining' do |option_key, option_flag, long_name = nil|
    it "allows later options to override earlier ones" do
      # Use long_name for the --no- form if available
      long = long_name || option_flag
      first_arg = "--no-#{long}"
      
      # First set to false, then true - should end up true
      args = [first_arg, "-#{option_flag}"]
      options, = ArgsParser.call(args)
      expect(options[option_key]).to eq(true)

      # First set to true, then false - should end up false
      args = ["-#{option_flag}", "-#{option_flag}-"]
      options, = ArgsParser.call(args)
      expect(options[option_key]).to eq(false)
    end
  end
  
  # Run tests for each boolean option
  BOOLEAN_OPTIONS.each do |option|
    context "for #{option[:key]} option" do
      include_examples 'respects default value',   option[:key], option[:default]
      include_examples 'handles positive formats', option[:key], option[:flag], option[:long_name]
      include_examples 'handles negative formats', option[:key], option[:flag], option[:long_name]
      include_examples 'option chaining',          option[:key], option[:flag], option[:long_name]
    end
  end

  # Environment variable tests
  context "when using RIKA_OPTIONS environment" do
    before do
      @original_env = ENV['RIKA_OPTIONS']
    end

    after do
      ENV['RIKA_OPTIONS'] = @original_env
    end

    it "reads options from environment variable" do
      ENV['RIKA_OPTIONS'] = "-m- -t -k -s- -a"
      options, = ArgsParser.call([])
      expect(options[:metadata]).to  eq(false)
      expect(options[:text]).to      eq(true)
      expect(options[:key_sort]).to  eq(true)
      expect(options[:source]).to    eq(false)
      expect(options[:as_array]).to  eq(true)
    end

    it "allows command line to override environment variable" do
      ENV['RIKA_OPTIONS'] = "-m- -t- -k- -s- -a"
      options, = ArgsParser.call(["-m", "-t", "-k"])
      expect(options[:metadata]).to  eq(true)
      expect(options[:text]).to      eq(true)
      expect(options[:key_sort]).to  eq(true)
      expect(options[:source]).to    eq(false)
      expect(options[:as_array]).to  eq(true)
    end
  end
end 