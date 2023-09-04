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
      expect { RikaCommand.new([fixture_path('tiny.txt')]).call }.to_not raise_error
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
      args_parser = ArgsParser.new
      allow(args_parser).to receive(:environment_options).and_return('-t-')
      options, _, _ = args_parser.call([])
      expect(options[:text]).to eq(false)
    end

    it 'overrides environment variable options with command line options' do
      env_format_arg = '-fyy'
      cmd_line_format = 'JJ'
      cmd_line_args = ["-f#{cmd_line_format}"]
      args_parser = ArgsParser.new
      allow(args_parser).to receive(:environment_options).and_return(env_format_arg)
      options, _, _ = args_parser.call(cmd_line_args)
      expect(options[:format]).to eq(cmd_line_format)
    end
  end

  describe '#set_output_formats' do
    RSpec.shared_examples 'verify_correct_output_formats_selected' do |format_chars, expected_m_formatter, expected_t_formatter|
      specify "correctly sets output formats when options are #{format_chars}" do
        rika_command = RikaCommand.new(["-f#{format_chars}"])
        rika_command.send(:prepare)
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
        expect { RikaCommand.new(["-f#{format_chars}"]).call }.to raise_error(SystemExit)
      end
    end

    include_examples 'verify_bad_output_format_exits', 'ax'
    include_examples 'verify_bad_output_format_exits', 'xa'
    include_examples 'verify_bad_output_format_exits', 'x'
  end

  describe '#warn_if_no_targets_specified' do
    it 'prints a warning if no targets are specified' do
      rika_command = RikaCommand.new([])
      allow(rika_command).to receive(:targets).and_return([])
      expect { rika_command.send(:report_and_exit_if_no_targets_specified) }.to raise_error(SystemExit)
      expect($stderr.string).to match(/No targets specified/)
    end
  end
end

