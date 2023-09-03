# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/rika_command'

describe RikaCommand do

  before do
    @original_stdout = $stdout
    @original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after do
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  describe '#run' do
    it 'should run' do
      expect { RikaCommand.new([]).run }.to_not raise_error
    end
  end

  describe '#parse_command_line' do
    specify 'returns a hash of options, a target array, and help text' do
      options, targets, help_text = RikaCommand.new([]).send(:parse_command_line)
      expect(options).to be_a(Hash)
      expect(targets).to be_an(Array)
      expect(help_text).to be_a(String)
    end

    context 'parse_options' do
      RSpec.shared_examples 'sets_options_correctly' do |args, option_key, expected_value|
        specify "correctly sets #{option_key} to #{expected_value} when args are #{args}" do
          rika_command = RikaCommand.new(args)
          allow(rika_command).to receive(:args).and_return(args)
          options, _, _ = rika_command.send(:parse_command_line)
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

  describe '#versions_string' do
    specify 'returns a Rika version and a Tika version' do
      expect(RikaCommand.new.send(:versions_string)).to match(
        /Versions:.*Rika: (\d+\.\d+\.\d+(-\w+)?).*Tika: (\d+\.\d+\.\d+(-\w+)?)/
      )
    end
  end

  describe 'environment variable processing' do
    it 'adds arguments from the environment to the args list' do
      rika_command = RikaCommand.new([])
      allow(rika_command).to receive(:environment_options).and_return('-t-')
      options, _, _ = rika_command.send(:parse_command_line)
      expect(options[:text]).to eq(false)
    end

    it 'overrides environment variable options with command line options' do
      env_format_arg = '-fyy'
      cmd_line_format = 'JJ'
      cmd_line_args = ["-f#{cmd_line_format}"]
      rika_command = RikaCommand.new(cmd_line_args)
      allow(rika_command).to receive(:environment_options).and_return(env_format_arg)
      options, _, _ = rika_command.send(:parse_command_line)
      expect(options[:format]).to eq(cmd_line_format)
    end
  end

  describe '#set_output_formats' do
    RSpec.shared_examples 'verify_correct_output_formats_selected' do |format_chars, expected_m_formatter, expected_t_formatter|
      specify "correctly sets output formats when options are #{format_chars}" do
        rika_command = RikaCommand.new(["-f#{format_chars}"])
        rika_command.send(:process_args)
        expect(rika_command.send(:metadata_formatter)).to eq(expected_m_formatter)
        expect(rika_command.send(:text_formatter)).to eq(expected_t_formatter)
      end
    end

    RF = Rika::Formatters
    include_examples('verify_correct_output_formats_selected', 'aj', RF::AWESOME_PRINT_FORMATTER, RF::JSON_FORMATTER)
    include_examples('verify_correct_output_formats_selected', 'Jy', RF::PRETTY_JSON_FORMATTER,   RF::YAML_FORMATTER)
    include_examples('verify_correct_output_formats_selected', 'ti', RF::TO_S_FORMATTER,          RF::INSPECT_FORMATTER)

    RSpec.shared_examples 'verify_bad_output_format_exits' do |format_chars|
      specify "exits when a bad output format is specified with #{format_chars}" do
        rika_command = RikaCommand.new(["-f#{format_chars}"])
        expect { rika_command.send(:process_args) }.to raise_error(SystemExit)
      end
    end

    include_examples 'verify_bad_output_format_exits', 'ax'
    include_examples 'verify_bad_output_format_exits', 'xa'
    include_examples 'verify_bad_output_format_exits', 'x'
  end
end

