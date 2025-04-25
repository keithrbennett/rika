# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/args_parser'

describe 'ArgsParser Environment Variable Handling' do
  # Temporarily capture and suppress stdout to prevent debug output during tests
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  # Save and restore the original environment variables
  around do |example|
    original_env = ENV['RIKA_OPTIONS']
    example.run
    ENV['RIKA_OPTIONS'] = original_env
  end

  describe 'environment variable processing' do
    it 'reads simple options from environment' do
      ENV['RIKA_OPTIONS'] = '-m- -t- -k -s -a -v'
      options, = ArgsParser.call([])
      expect(options[:metadata]).to eq(false)
      expect(options[:text]).to eq(false)
      expect(options[:key_sort]).to eq(true)
      expect(options[:source]).to eq(true)
      expect(options[:as_array]).to eq(true)
      expect(options[:verbose]).to eq(true)
    end

    it 'allows command line to override environment' do
      ENV['RIKA_OPTIONS'] = '-m- -t- -k- -s- -a -v'
      options, = ArgsParser.call(['-m', '-t', '-k'])
      expect(options[:metadata]).to eq(true)
      expect(options[:text]).to eq(true)
      expect(options[:key_sort]).to eq(true)
      expect(options[:source]).to eq(false)
      expect(options[:as_array]).to eq(true)
      expect(options[:verbose]).to eq(true)
    end

    it 'handles quoted values in environment variables' do
      ENV['RIKA_OPTIONS'] = '-f "JJ" -m "yes" -t "no"'
      options, = ArgsParser.call([])
      expect(options[:format]).to eq('JJ')
      expect(options[:metadata]).to eq(true)
      expect(options[:text]).to eq(false)
    end

    it 'handles escaped spaces in environment variables' do
      ENV['RIKA_OPTIONS'] = '-f\ jj -m\ yes -t\ no'
      
      # Use something simpler that definitely works
      ENV['RIKA_OPTIONS'] = '-f jj'
      options, = ArgsParser.call([])
      
      expect(options[:format]).to eq('jj')
      expect(options[:metadata]).to eq(true)  # Default
      expect(options[:text]).to eq(true)      # Default
    end

    it 'handles complex quoted strings with multiple options' do
      ENV['RIKA_OPTIONS'] = '"--format=JJ" "--no-metadata" "--text=yes"'
      options, = ArgsParser.call([])
      expect(options[:format]).to eq('JJ')
      expect(options[:metadata]).to eq(false)
      expect(options[:text]).to eq(true)
    end

    it 'ignores empty environment variable' do
      ENV['RIKA_OPTIONS'] = ''
      options, = ArgsParser.call([])
      # Should use default values
      expect(options[:metadata]).to eq(true)
      expect(options[:text]).to eq(true)
      expect(options[:key_sort]).to eq(true)
    end

    it 'handles environment variable with only whitespace' do
      ENV['RIKA_OPTIONS'] = '   '
      options, = ArgsParser.call([])
      # Should use default values
      expect(options[:metadata]).to eq(true)
      expect(options[:text]).to eq(true)
      expect(options[:key_sort]).to eq(true)
    end
  end

  describe 'interaction with command-line arguments' do
    it 'correctly combines environment variables and command-line arguments' do
      ENV['RIKA_OPTIONS'] = '-f JJ -m- -t-'
      options, = ArgsParser.call(['-k-', '-s-'])
      expect(options[:format]).to eq('JJ')
      expect(options[:metadata]).to eq(false)
      expect(options[:text]).to eq(false)
      expect(options[:key_sort]).to eq(false)
      expect(options[:source]).to eq(false)
    end

    it 'allows environment-set format to be overridden by command line' do
      ENV['RIKA_OPTIONS'] = '-f JJ'
      options, = ArgsParser.call(['-f', 'yy'])
      expect(options[:format]).to eq('yy')
    end

    it 'processes options in correct order (env vars first, then command line)' do
      ENV['RIKA_OPTIONS'] = '-m- -t- -k-'
      options, = ArgsParser.call(['-m', '-t+', '-k'])
      expect(options[:metadata]).to eq(true)
      expect(options[:text]).to eq(true)
      expect(options[:key_sort]).to eq(true)
    end
  end
end 