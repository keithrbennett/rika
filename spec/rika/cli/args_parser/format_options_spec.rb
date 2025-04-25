# frozen_string_literal: true

require 'spec_helper'
require 'rika/cli/args_parser'

describe 'ArgsParser Format Options Handling' do
  # Temporarily capture and suppress stdout to prevent debug output during tests
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  describe 'format option parsing' do
    it 'uses default format when not specified' do
      options, = ArgsParser.call([])
      expect(options[:format]).to eq('at')
    end

    context 'with single-character format' do
      it 'duplicates the character for both metadata and text' do
        options, = ArgsParser.call(['-f', 'y'])
        expect(options[:format]).to eq('yy')
      end

      it 'handles single-character format with hyphen' do
        options, = ArgsParser.call(['-fy'])
        expect(options[:format]).to eq('yy')
      end

      it 'handles single-character format with equals' do
        options, = ArgsParser.call(['--format=y'])
        expect(options[:format]).to eq('yy')
      end
    end

    context 'with two-character format' do
      it 'uses first character for metadata, second for text' do
        options, = ArgsParser.call(['-f', 'yj'])
        expect(options[:format]).to eq('yj')
      end

      it 'handles two-character format with hyphen' do
        options, = ArgsParser.call(['-fyj'])
        expect(options[:format]).to eq('yj')
      end

      it 'handles two-character format with equals' do
        options, = ArgsParser.call(['--format=yj'])
        expect(options[:format]).to eq('yj')
      end
    end

    context 'with formats longer than two characters' do
      it 'truncates to the first two characters' do
        options, = ArgsParser.call(['-f', 'aijytt'])
        expect(options[:format]).to eq('ai')
      end

      it 'truncates with hyphen notation' do
        options, = ArgsParser.call(['-faijytt'])
        expect(options[:format]).to eq('ai')
      end

      it 'truncates with equals notation' do
        options, = ArgsParser.call(['--format=aijytt'])
        expect(options[:format]).to eq('ai')
      end
    end
  end

  describe 'format validation' do
    it 'accepts all valid format characters' do
      valid_formats = %w[a i j J t y]
      
      valid_formats.each do |format|
        options, = ArgsParser.call(['-f', format])
        expect(options[:format]).to eq(format * 2)
      end
    end

    it 'raises error for invalid format characters' do
      expect {
        ArgsParser.call(['-f', 'z'])
      }.to raise_error(SystemExit)
    end

    it 'raises error if either character is invalid' do
      expect {
        ArgsParser.call(['-f', 'az'])
      }.to raise_error(SystemExit)
      
      expect {
        ArgsParser.call(['-f', 'za'])
      }.to raise_error(SystemExit)
    end
  end

  describe 'interaction with other options' do
    it 'preserves format when using other options' do
      options, = ArgsParser.call(['-f', 'JJ', '-m-', '-t-', '-k-'])
      expect(options[:format]).to eq('JJ')
      expect(options[:metadata]).to eq(false)
      expect(options[:text]).to eq(false)
      expect(options[:key_sort]).to eq(false)
    end

    it 'allows format to be overridden by later options' do
      options, = ArgsParser.call(['-f', 'aa', '-f', 'JJ'])
      expect(options[:format]).to eq('JJ')
    end

    it 'handles complex option combinations' do
      options, = ArgsParser.call(['-f', 'jy', '-m-', '-a', '-s-'])
      expect(options[:format]).to eq('jy')
      expect(options[:metadata]).to eq(false)
      expect(options[:as_array]).to eq(true)
      expect(options[:source]).to eq(false)
    end
  end

  # This test may need to be adapted if the actual implementation behavior is different
  describe 'edge cases' do
    it 'handles empty format string' do
      # Different implementations might handle this differently
      # Some might use default, others might error
      expect {
        ArgsParser.call(['-f', ''])
      }.to raise_error(SystemExit)
    end

    it 'handles format with whitespace' do
      expect {
        ArgsParser.call(['-f', ' a'])
      }.to raise_error(SystemExit)
      
      expect {
        ArgsParser.call(['-f', 'a '])
      }.to raise_error(SystemExit)
    end
  end
end 