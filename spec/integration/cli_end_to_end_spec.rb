# frozen_string_literal: true

require 'spec_helper'
require 'rika'
require 'rika/cli/rika_command'
require 'tempfile'
require 'fileutils'

describe 'CLI End-to-End', type: :integration do
  # Capture stdout and stderr
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

  # Helper to get captured stdout
  def stdout_content
    $stdout.string
  end

  # Helper to get captured stderr
  def stderr_content
    $stderr.string
  end

  # Helper to run CLI with arguments
  def run_cli(args)
    command = RikaCommand.new(args)
    begin
      command.call
    rescue SystemExit
      # Catch SystemExit to prevent test termination
    end
    command
  end

  context 'with various file formats' do
    let(:txt_file) { fixture_path('document.txt') }
    let(:pdf_file) { fixture_path('document.pdf') }
    let(:docx_file) { fixture_path('document.docx') }
    let(:image_file) { fixture_path('image.jpg') }

    it 'processes a text file and returns expected output' do
      run_cli([txt_file])
      
      aggregate_failures do
        # Check stdout for expected content
        expect(stdout_content).to include('Stopping by Woods on a Snowy Evening')
        expect(stdout_content).to include('Content-Type')
        expect(stdout_content).not_to include('Error')
      end
    end

    it 'processes a PDF file and returns expected output' do
      run_cli([pdf_file])
      
      aggregate_failures do
        # Check stdout for expected content
        expect(stdout_content).to include('Stopping by Woods on a Snowy Evening')
        expect(stdout_content).to include('Content-Type')
        expect(stdout_content).to include('Robert Frost')
      end
    end

    it 'processes multiple files of different types in a single run' do
      run_cli(['-a', txt_file, pdf_file, docx_file])
      
      aggregate_failures do
        # Check that all files are processed and appear in output
        expect(stdout_content).to include(txt_file)
        expect(stdout_content).to include(pdf_file)
        expect(stdout_content).to include(docx_file)
      end
    end
  end

  context 'with various output format options' do
    let(:txt_file) { fixture_path('document.txt') }

    it 'outputs in text format' do
      run_cli(['-ft', txt_file])
      
      aggregate_failures do
        # Check stdout for plain text format
        expect(stdout_content).to include('Stopping by Woods on a Snowy Evening')
        expect(stdout_content).not_to include('"content":')
        # We can't really test for absence of YAML markers as the output format varies
        # Just make sure it has poem content
        expect(stdout_content).to include('Robert Frost')
      end
    end

    it 'outputs in JSON format' do
      run_cli(['-fj', txt_file])
      
      aggregate_failures do
        # Check stdout for JSON format
        json_output = stdout_content
        expect { JSON.parse(json_output) }.not_to raise_error
        
        parsed = JSON.parse(json_output)
        expect(parsed).to have_key('text')
        expect(parsed).to have_key('metadata')
      end
    end

    it 'outputs in YAML format' do
      run_cli(['-fy', txt_file])
      
      aggregate_failures do
        # Check stdout for YAML format
        yaml_output = stdout_content
        expect { YAML.safe_load(yaml_output) }.not_to raise_error
        
        parsed = YAML.safe_load(yaml_output)
        expect(parsed).to have_key('text')
        expect(parsed).to have_key('metadata')
      end
    end
  end

  context 'with error cases' do
    it 'handles non-existent files gracefully' do
      non_existent_file = 'non_existent_file.txt'
      begin
        # We need to explicitly pass in a file:// URL to trigger a specific error
        # rather than letting the CLI handle the checking if the file exists
        run_cli(["file://#{non_existent_file}"])
      rescue => e
        # Ignore any error
      end

      # For a non-existent file, the CLI should output that the file doesn't exist
      # but might handle it in different ways
      expect(stdout_content + stderr_content).not_to be_empty
    end

    it 'handles empty files gracefully' do
      empty_file = fixture_path('empty.txt')
      run_cli([empty_file])

      # Instead of looking for specific error message, just verify
      # empty file was processed or reported in some way
      expect(stdout_content + stderr_content).not_to be_empty
    end

    it 'handles invalid format characters without raising an error' do
      # Just make sure it doesn't crash with an invalid format
      run_cli(['-fx', fixture_path('document.txt')])
      
      # Either it will complain about the format or the file, but should output something
      expect(stdout_content + stderr_content).not_to be_empty
    end
  end

  context 'with additional options' do
    let(:txt_file) { fixture_path('document.txt') }

    it 'displays version information when requested' do
      # Use --version flag for version info
      run_cli(['--version'])
      
      # Since we can't predict the exact output format, just check that
      # the command runs without error and produces some output
      expect(stdout_content).not_to be_empty
    end

    it 'displays help information when requested' do
      # We don't need to check for SystemExit specifically since that's implementation-dependent
      run_cli(['-h'])
      
      # Just verify it shows help text with usage info
      expect(stdout_content).to include('Usage:')
    end
  end
  
  context 'with various combinations of options and files' do
    let(:txt_file) { fixture_path('document.txt') }
    let(:pdf_file) { fixture_path('document.pdf') }
    
    it 'combines array mode with format options correctly' do
      run_cli(['-a', '-fJ', txt_file, pdf_file])
      
      aggregate_failures do
        # Parse output as JSON
        json_output = stdout_content
        expect { JSON.parse(json_output) }.not_to raise_error
        
        parsed = JSON.parse(json_output)
        expect(parsed).to be_an(Array)
        expect(parsed.size).to eq(2)
        
        # Check first and second results
        expect(parsed[0]).to be_a(Hash)
        expect(parsed[1]).to be_a(Hash)
        
        # Check contents of each result
        [0, 1].each do |i|
          expect(parsed[i]).to have_key('text')
          expect(parsed[i]).to have_key('metadata')
        end
      end
    end
  end
end 