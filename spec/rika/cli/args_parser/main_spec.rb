# frozen_string_literal: true

require 'spec_helper'

require 'rika/cli/args_parser'

describe ArgsParser do
  let(:versions_regex) { /Versions:.*Rika: (\d+\.\d+\.\d+(-\w+)?).*Tika: (\d+\.\d+\.\d+(-\w+)?)/ }
  let(:fixtures_dir) { File.expand_path(File.join(File.dirname(__FILE__), '../../fixtures')) }

  specify 'returns a hash of options, a target array, and help text' do
    options, targets, help_text = described_class.call([])
    expect(options).to be_a(Hash)
    expect(targets).to be_an(Array)
    expect(help_text).to be_a(String)
  end

  context 'when parsing options' do
    RSpec.shared_examples 'sets_options_correctly' do |args, option_key, expected_value|
      specify "correctly sets #{option_key} to #{expected_value} when args are #{args}" do
        options, _, _ = described_class.call(args)
        expect(options[option_key]).to eq(expected_value)
      end
    end

    # Test default option values:
    include_examples('sets_options_correctly', [], :as_array, false)
    include_examples('sets_options_correctly', [], :text, true)
    include_examples('sets_options_correctly', [], :metadata, true)
    include_examples('sets_options_correctly', [], :format, 'at')
    include_examples('sets_options_correctly', [], :key_sort, true)
    include_examples('sets_options_correctly', [], :source, true)

    # Test -a as_array option:
    include_examples('sets_options_correctly', %w[-a], :as_array, true)
    include_examples('sets_options_correctly', %w[--as_array], :as_array, true)
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

    # Test -k key sort option:
    include_examples('sets_options_correctly', %w[-k-], :key_sort, false)

    # Test -s source option:
    include_examples('sets_options_correctly', %w[-s-], :source, false)
  end

  describe '#versions_string' do
    specify 'returns a Rika version and a Tika version' do
      expect(described_class.new.send(:versions_string)).to match(versions_regex)
    end
  end

  context 'when processing environment variables' do
    it 'adds arguments from the environment to the args list' do
      args_parser = described_class.new
      allow(args_parser).to receive(:environment_options).and_return('-t-')
      options, _, _ = args_parser.call([])
      expect(options[:text]).to be(false)
    end

    it 'overrides environment variable options with command line options' do
      env_format_arg = '-fyy'
      cmd_line_format = 'JJ'
      cmd_line_args = ["-f#{cmd_line_format}"]
      args_parser = described_class.new
      allow(args_parser).to receive(:environment_options).and_return(env_format_arg)
      options, _, _ = args_parser.call(cmd_line_args)
      expect(options[:format]).to eq(cmd_line_format)
    end
  end

  describe 'DEFAULT_OPTIONS hash' do
    specify 'has the correct default values' do
      expect(described_class::DEFAULT_OPTIONS).to eq(
        as_array: false,
        text: true,
        metadata: true,
        format: 'at',
        key_sort: true,
        source: true,
        verbose: false
      )
    end

    specify 'is frozen' do
      expect(described_class::DEFAULT_OPTIONS).to be_frozen
    end
  end

  describe '#process_args_for_targets' do
    let(:args_parser) { described_class.new }
    
    it 'removes directories from the target array' do
      allow(args_parser).to receive(:args).and_return([fixtures_dir])
      targets, _ = args_parser.send(:process_args_for_targets)
      expect(targets).to be_empty
    end
    
    it 'keeps regular files in the target array' do
      tiny_filespec = fixture_path('tiny.txt')
      allow(args_parser).to receive(:args).and_return([tiny_filespec])
      targets, _ = args_parser.send(:process_args_for_targets)
      expect(targets).to eq([tiny_filespec])
    end
    
    context 'with wildcard patterns' do
      it 'expands wildcard patterns using Dir.glob' do
        pattern = fixture_path('*.txt')
        allow(args_parser).to receive(:args).and_return([pattern])
        
        targets, _ = args_parser.send(:process_args_for_targets)
        # Verify we got at least one .txt file and no directories
        expect(targets).not_to be_empty
        expect(targets.all? { |f| f.end_with?('.txt') }).to be true
      end
      
      it 'removes directories from the expanded results' do
        # Ensure the fixtures directory exists
        FileUtils.mkdir_p(fixtures_dir) unless File.directory?(fixtures_dir)
        
        # Create a test file in the fixtures directory to ensure we have at least one file
        test_file_path = File.join(fixtures_dir, 'test_file_for_wildcard.txt')
        File.write(test_file_path, 'test content') unless File.exist?(test_file_path)
        
        # Use a pattern that will match both files and the fixtures dir
        pattern = File.join(fixtures_dir, '*')
        allow(args_parser).to receive(:args).and_return([pattern])
        
        begin
          targets, _ = args_parser.send(:process_args_for_targets)
          # Verify we got some files but no directories
          expect(targets).not_to be_empty
          expect(targets.any? { |f| File.directory?(f) }).to be false
        ensure
          # Clean up test file
          File.unlink(test_file_path) if File.exist?(test_file_path)
        end
      end
    end
    
    context 'with empty files' do
      it 'flags empty files in the issues hash' do
        empty_file_path = fixture_path('empty.txt')
        allow(args_parser).to receive(:args).and_return([empty_file_path])
        
        targets, issues = args_parser.send(:process_args_for_targets)
        expect(targets).to be_empty
        expect(issues[:empty_file]).to include(empty_file_path)
      end
    end
  end
end
