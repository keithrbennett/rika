# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/rika_command'

RF = Rika::Formatters

describe RikaCommand do
  let(:versions_regex) { /Versions:.*Rika: (\d+\.\d+\.\d+(-\w+)?).*Tika: (\d+\.\d+\.\d+(-\w+)?)/ }

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

  describe '#call' do
    specify 'call should run the command without error' do
      expect { described_class.new([fixture_path('tiny.txt')]).call }.not_to raise_error
    end

    specify 'prints version and exits when -v or --version is specified' do
      expect { described_class.new(%w[-v]).call }.to output(versions_regex).to_stdout.and raise_error(SystemExit)
      expect { described_class.new(%w[--version]).call }.to output(versions_regex).to_stdout.and raise_error(SystemExit)
    end

    specify 'prints help and exits when -h or --help is specified' do
      regex = /Usage: rika \[options\] <file or url> /m
      expect { described_class.new(%w[-h]).call }.to output(regex).to_stdout.and raise_error(SystemExit)
    end

    specify 'when run in array mode, outputs the string representation of an array of parse results' do
      original_stdout = $stdout
      $stdout = StringIO.new
      begin
        tiny_filespec = fixture_path('tiny.txt')
        args = ['-a', '-fJ', tiny_filespec, tiny_filespec]
        described_class.new(args).call
        output = $stdout.string
        object = JSON.parse(output)
        expect(object).to be_an(Array)
        expect(object.size).to eq(2)
        expect(object.map(&:class)).to eq([Hash, Hash])
      ensure
        $stdout = original_stdout
      end
    end
  end

  describe '#single_document_output' do
    RSpec.shared_examples 'verify_result_is_hash' do |format_chars, parser|
      specify "correctly uses result hash for JSON and YAML when options are #{format_chars}" do
        original_stdout = $stdout
        $stdout = StringIO.new
        begin
          rika_command = described_class.new(["-f#{format_chars}", fixture_path('tiny.txt')])
          rika_command.call
          output = $stdout.string
          warn output
          result_hash = parser.call(output)
          expect(result_hash).to be_a(Hash)
          expect(result_hash['metadata']).to be_a(Hash)
          expect(result_hash['text']).to be_a(String)
        ensure
          $stdout = original_stdout
        end
      end
    end

    include_examples('verify_result_is_hash', 'JJ', ->(s) { JSON.parse(s) })
    include_examples('verify_result_is_hash', 'jj', ->(s) { JSON.parse(s) })
    include_examples('verify_result_is_hash', 'yy', ->(s) { YAML.safe_load(s) })
  end

  describe '#set_output_formats' do
    RSpec.shared_examples 'verify_correct_output_formats_selected' \
      do |format_chars, expected_m_formatter, expected_t_formatter|
      specify "correctly sets output formats when options are #{format_chars}" do
        rika_command = described_class.new(["-f#{format_chars}"])
        rika_command.send(:prepare)
        expect(rika_command.send(:metadata_formatter)).to eq(expected_m_formatter)
        expect(rika_command.send(:text_formatter)).to eq(expected_t_formatter)
      end
    end

    include_examples('verify_correct_output_formats_selected', 'aj', RF::AWESOME_PRINT_FORMATTER, RF::JSON_FORMATTER)
    include_examples('verify_correct_output_formats_selected', 'Jy', RF::PRETTY_JSON_FORMATTER,   RF::YAML_FORMATTER)
    include_examples('verify_correct_output_formats_selected', 'ti', RF::TO_S_FORMATTER,          RF::INSPECT_FORMATTER)

    RSpec.shared_examples 'verify_bad_output_format_exits' do |format_chars|
      specify "exits when a bad output format is specified with #{format_chars}" do
        expect { described_class.new(["-f#{format_chars}"]).call }.to raise_error(SystemExit)
      end
    end

    include_examples 'verify_bad_output_format_exits', 'ax'
    include_examples 'verify_bad_output_format_exits', 'xa'
    include_examples 'verify_bad_output_format_exits', 'x'
  end

  describe '#report_and_exit_if_no_targets_specified' do
    it 'prints a warning if no targets are specified' do
      rika_command = described_class.new([])
      allow(rika_command).to receive_messages(
        targets: []
      )
      # Use allow instead of expect to avoid SystemExit in test
      allow(rika_command).to receive(:exit)

      rika_command.send(:report_and_exit_if_no_targets_specified)
      
      # Check the output
      output = $stderr.string
      expect(output).to match(/No valid targets specified/)
      expect(output).to match(/Run with '-h' option for help/)
    end
  end

  describe '#source_output_string' do
    let(:rika_command) { described_class.new([]) }
    let(:sample_filespec) { 'path/to/file.ext' }
    let(:sample_output_string) { rika_command.send(:source_output_string, sample_filespec) }
    let(:sample_output_lines) { sample_output_string.lines.map(&:chomp) }
    let(:header_trailer_line) { '-' * 79 }

    specify 'it has a header and trailer line' do
      expect(sample_output_lines[0]).to eq(header_trailer_line)
      expect(sample_output_lines[2]).to eq(header_trailer_line)
    end

    specify 'information line is well formed' do
      line = sample_output_lines[1]
      expect(line).to match("Source: #{sample_filespec}")
    end
  end

  describe 'empty file behavior' do
    let(:empty_file_path) { fixture_path('empty.txt') }
    let(:something_file_path) { fixture_path('something.txt') } # containts "something"

    specify 'parsing an empty file does not interrupt parsing of subsequent files' do
      expect {
        described_class.new([empty_file_path, something_file_path]).call
      }.to output(/something/).to_stdout
    end
    
    specify 'empty files are reported in the bad_targets hash' do
      command = described_class.new([empty_file_path])
      allow(command).to receive(:report_and_exit_if_no_targets_specified)
      command.call
      
      # Check if the empty file is tracked in the bad_targets hash
      expect(command.bad_targets[:empty_file]).to include(empty_file_path)
    end
  end
  
  describe 'integration with ArgsParser issues' do
    # Create a default options hash with format so that set_output_formats will work
    let(:default_options) { { format: 'at' } }
    
    it 'transfers issues from ArgsParser to bad_targets' do
      # Create a mock ArgsParser that returns a specific issues hash
      mock_issues = {
        non_existent_file: ['missing.txt'],
        empty_file: ['empty.txt']
      }
      
      allow(ArgsParser).to receive(:call).and_return([default_options, [], 'help text', mock_issues])
      
      command = described_class.new([])
      # Skip exit check for no targets in tests
      allow(command).to receive(:report_and_exit_if_no_targets_specified)
      command.send(:prepare)
      
      # Verify issues were transferred to bad_targets
      expect(command.bad_targets[:non_existent_file]).to include('missing.txt')
      expect(command.bad_targets[:empty_file]).to include('empty.txt')
    end
    
    it 'handles multiple issues in each category' do
      mock_issues = {
        non_existent_file: ['missing1.txt', 'missing2.txt'],
        invalid_url: ['http://:invalid1', 'http://:invalid2']
      }
      
      allow(ArgsParser).to receive(:call).and_return([default_options, [], 'help text', mock_issues])
      
      command = described_class.new([])
      # Skip exit check for no targets in tests
      allow(command).to receive(:report_and_exit_if_no_targets_specified)
      command.send(:prepare)
      
      # Verify all issues were transferred correctly
      expect(command.bad_targets[:non_existent_file]).to eq(['missing1.txt', 'missing2.txt'])
      expect(command.bad_targets[:invalid_url]).to eq(['http://:invalid1', 'http://:invalid2'])
    end
    
    it 'aggregates issues from different sources' do
      # Create a mock ArgsParser that returns some issues
      mock_issues = { non_existent_file: ['missing.txt'] }
      
      allow(ArgsParser).to receive(:call).and_return([default_options, [], 'help text', mock_issues])
      
      command = described_class.new([])
      # Skip exit check for no targets in tests
      allow(command).to receive(:report_and_exit_if_no_targets_specified)
      command.send(:prepare)
      
      # Manually add an error from another source
      command.send(:handle_parse_error, StandardError.new('test error'), 'file.txt', :io_error)
      
      # Verify both types of issues are in bad_targets
      expect(command.bad_targets[:non_existent_file]).to include('missing.txt')
      expect(command.bad_targets[:io_error]).to include('file.txt')
    end
  end
end
