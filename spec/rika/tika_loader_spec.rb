# frozen_string_literal: true

require 'spec_helper'
require 'rika/tika_loader'

describe Rika::TikaLoader do
  describe '.require_tika' do
    it 'returns the correct Tika jar file path' do
      expect(described_class.require_tika).to match(/tika-app-.*\.jar/)
    end

    it 'calls print_message_and_exit if the Tika jar file cannot be loaded' do
      allow(ENV).to receive(:[]).with('TIKA_JAR_FILESPEC').and_return('nonexistent_file')
      expect { described_class.require_tika }.to raise_error(Rika::TikaLoadError) \
        .with_message(/Unable to load Tika jar file from nonexistent_file./)
    end
  end

  describe '.specified_tika_filespec' do
    it 'returns the correct Tika jar file path' do
      expect(described_class.send(:specified_tika_filespec)).to match(/tika-app-.*\.jar/)
    end

    it 'raises a TikaLoadError if the Tika jar filespec is not specified at all in TIKA_JAR_FILESPEC' do
      allow(ENV).to receive(:[]).with('TIKA_JAR_FILESPEC').and_return(nil)
      expect { described_class.send(:specified_tika_filespec) }.to raise_error(Rika::TikaLoadError) \
        .with_message(/Environment variable TIKA_JAR_FILESPEC is not set./)
    end
  end

  describe '.print_message_and_exit' do
    it 'prints the correct message and exits with an exit code of 1' do
      stderr_orig = $stderr
      $stderr = StringIO.new

      begin
        expect { described_class.send(:print_message_and_exit, 'message') }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
        expect($stderr.string).to match(/message/)
      ensure
        $stderr = stderr_orig
      end
    end
  end

  describe '.formatted_error_message' do
    it 'returns the correct message' do
      message = 'This is a test message.'
      expect(described_class.send(:formatted_error_message, message)).to match(/#{message}/)
    end

    it 'returns the correct banner' do
      expect(described_class.send(:formatted_error_message, 'message').lines.grep(/!{79}/).size).to be >= 2
    end
  end
end
