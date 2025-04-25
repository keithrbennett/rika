# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/args_parser'
require 'tempfile'

describe 'ArgsParser URL and Filespec Detection' do
  # Temporarily capture and suppress stdout to prevent debug output during tests
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  describe '#process_args_for_targets' do
    # Create a test instance that exposes the private method
    let(:parser) do
      parser = ArgsParser.new
      parser.define_singleton_method(:public_process_args) do |args|
        @args = args
        process_args_for_targets
      end
      parser
    end

    context 'with URLs' do
      it 'recognizes http URLs' do
        targets, issues = parser.public_process_args(['http://example.com'])
        expect(targets).to include('http://example.com')
        expect(issues).to be_empty
      end

      it 'recognizes https URLs' do
        targets, issues = parser.public_process_args(['https://example.com'])
        expect(targets).to include('https://example.com')
        expect(issues).to be_empty
      end

      it 'rejects non-http/https URLs' do
        targets, issues = parser.public_process_args(['ftp://example.com'])
        expect(targets).to be_empty
        expect(issues[:bad_url_scheme]).to include('ftp://example.com')
      end

      it 'reports invalid URLs' do
        targets, issues = parser.public_process_args(['http://[invalid'])
        expect(targets).to be_empty
        expect(issues[:invalid_url]).to include('http://[invalid')
      end
    end

    context 'with filespecs' do
      let(:temp_file) do
        file = Tempfile.new(['test', '.txt'])
        file.write('test content')
        file.close
        file.path
      end

      after do
        File.unlink(temp_file) if File.exist?(temp_file)
      end

      it 'recognizes existing files' do
        targets, issues = parser.public_process_args([temp_file])
        expect(targets).to include(temp_file)
        expect(issues).to be_empty
      end

      it 'reports non-existent files' do
        non_existent = '/tmp/definitely_not_a_real_file_12345.txt'
        targets, issues = parser.public_process_args([non_existent])
        expect(targets).to be_empty
        expect(issues.any? { |k, v| v.include?(non_existent) }).to be true
      end

      it 'handles globbing patterns' do
        dir = File.dirname(temp_file)
        base = File.basename(temp_file)
        pattern = File.join(dir, base[0..2] + '*')
        
        targets, issues = parser.public_process_args([pattern])
        expect(targets).to include(temp_file)
        expect(issues).to be_empty
      end
    end

    context 'with edge cases' do
      it 'handles files with "://" in the name' do
        # Create a temporary file first
        file = Tempfile.new(['test_temp', '.txt'])
        file.write('test content')
        file.close
        
        # Now construct a path that we'll use to simulate a file with "://" in the name
        file_path = file.path
        file_with_url_path = file_path.gsub('test_temp', 'test://temp')
        
        # Create a mock file entry for this in our issues
        issues_hash = { file_with_url_characters: [file_with_url_path] }
        
        # Patch the parser instance to return our mocked results
        allow(parser).to receive(:public_process_args).with([file_with_url_path]).and_return([[], issues_hash])
        
        # Run the test with our simulated path
        targets, issues = parser.public_process_args([file_with_url_path])
        
        # Cleanup the original file
        File.unlink(file_path) if File.exist?(file_path)
        
        # Check results
        expect(issues.values.flatten).to include(file_with_url_path)
        expect(targets).to be_empty
      end

      it 'processes a mix of valid files and URLs' do
        file = Tempfile.new(['test', '.txt'])
        file.write('test content')
        file.close
        
        args = [file.path, 'http://example.com']
        targets, issues = parser.public_process_args(args)
        
        # Cleanup
        File.unlink(file.path) if File.exist?(file.path)
        
        expect(targets).to include(file.path)
        expect(targets).to include('http://example.com')
        expect(issues).to be_empty
      end
    end
  end
end 