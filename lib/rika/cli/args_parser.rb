# frozen_string_literal: true

require 'optparse'
require 'shellwords'
require 'uri'
require 'awesome_print'
require_relative 'rika_command'

# Processes the array of arguments (ARGV by default) and returns the options, targets, and help string.
class ArgsParser
  attr_reader :args, :options, :option_parser
  private     :args, :options, :option_parser

  DEFAULT_OPTIONS =
    {
      as_array: false,
      format: 'at', # AwesomePrint for metadata, to_s for text content
      metadata: true,
      text: true,
      source: true,
      key_sort: true,
      dry_run: false,
    }.freeze

  # Parses the command line arguments.
  # Shorthand for ArgsParser.new.call. This call is recommended to protect the caller in case
  # this functionality is repackaged as a Module or otherwise modified.
  # @param [Array] args the command line arguments (overridable for testing, etc.)
  # @return [Array<Hash,Array,String,Hash>] [options, targets, help_string, issues],
  #   or exits if help or version requested or no targets specified.
  def self.call(args = ARGV)
    new.call(args)
  end

  # Parses the command line arguments.
  # @param [Array] args the command line arguments (overridable for testing, etc.)
  # @return [Array<Hash,Array,String,Hash>] [options, targets, help_string, issues],
  #   or exits if help or version requested or no targets specified.
  def call(args = ARGV)
    @args = args
    @options = DEFAULT_OPTIONS.dup
    prepend_environment_args
    @option_parser = create_option_parser
    option_parser.parse!(args)
    postprocess_format_options
    targets, issues = process_args_for_targets
    [options, targets, option_parser.help, issues]
  end

  # -------------------------------------------------------
  private
  # -------------------------------------------------------

  # @return [OptionParser]
  def create_option_parser
    OptionParser.new do |opts|
      opts.banner =  <<~BANNER
        Rika v#{Rika::VERSION} (Tika v#{Rika.tika_version}) - #{Rika::PROJECT_URL}

        Usage: rika [options] <file or url> [...file or url...]
        Output formats are: [a]wesome_print, [t]o_s, [i]nspect, [j]son), [J] for pretty json, and [y]aml.
        If a format contains two letters, the first will be used for metadata, the second for text.
        Values for the text, metadata, and as_array boolean options may be specified as follows:
          Enable:  +, true,  yes, [empty]
          Disable: -, false, no, [long form option with no- prefix, e.g. --no-metadata]

        ⚠️ IMPORTANT: Always quote wildcard patterns when files might contain special characters!
          - Double quotes: "*.pdf" (allows variable expansion)
          - Single quotes: '*.pdf' (prevents all shell interpretation)
          Use -n/--dry-run to preview command execution and check for issues.

      BANNER

      format_message = 'Output format (default: at)'
      opts.on('-f', '--format FORMAT', format_message) do |format|
        options[:format] = format
      end

      opts.on('-m', '--[no-]metadata [FLAG]', TrueClass, 'Output metadata (default: true)') do |v|
        options[:metadata] = (v.nil? ? true : v)
      end

      opts.on('-t', '--[no-]text [FLAG]', TrueClass, 'Output text (default: true)') do |v|
        options[:text] = (v.nil? ? true : v)
      end

      opts.on('-k', '--[no-]key-sort [FLAG]', TrueClass, 'Sort metadata keys case insensitively (default: true)') do |v|
        options[:key_sort] = (v.nil? ? true : v)
      end

      opts.on('-s', '--[no-]source [FLAG]', TrueClass, 'Output document source file or URL (default: true)') do |v|
        options[:source] = (v.nil? ? true : v)
      end

      opts.on('-a', '--[no-]as-array [FLAG]', TrueClass,
              'Output all parsed results as an array (default: false)') do |v|
        options[:as_array] = (v.nil? ? true : v)
      end

      opts.on('-n', '--[no-]dry-run [FLAG]', TrueClass, 'Show what would be done without executing (default: false)') do |v|
        options[:dry_run] = (v.nil? ? true : v)
      end

      opts.on('-v', '--version', 'Output software versions') do
        puts versions_string
        exit
      end

      opts.on('-h', '--help', 'Output help') do
        RikaCommand.output_help_text(opts)
        exit
      end
    end
  end

  # Fills in the second format option character if absent, and removes any excess characters
  # @return [String] format options 2-character value, e.g. 'at'
  def postprocess_format_options
    # If only one format letter is specified, use it for both metadata and text.
    options[:format] *= 2 if options[:format].length == 1

    # Ignore and remove extra characters after the first two format characters.
    options[:format] = options[:format][0..1]
    
    # Validate format characters
    valid_formats = %w[a i j J t y]
    format_chars = options[:format].chars
    
    if options[:format].strip.empty? || format_chars.any? { |c| !valid_formats.include?(c) }
      $stderr.puts "Error: Invalid format characters in '#{options[:format]}'. Valid characters are: #{valid_formats.join(', ')}"
      exit 1
    end
  end

  # If the user wants to specify options in an environment variable ("RIKA_OPTIONS"),
  # then this method will insert those options at the beginning of the `args` array,
  # where they can be overridden by command line arguments.
  def prepend_environment_args
    env_opt_string = environment_options
    args_to_prepend = Shellwords.shellsplit(env_opt_string)
    args.unshift(args_to_prepend).flatten!
  end

  # @return [String] the value of the RIKA_OPTIONS environment variable if present, else ''.
  def environment_options
    env_value = ENV['RIKA_OPTIONS'] || ''
    # Necessary to handle escaped spaces and other special characters consistently:
    env_value.dup.force_encoding('UTF-8')
  end

  # @return [String] string containing versions of Rika and Tika, with labels
  def versions_string
    java_version = Java::java.lang.System.getProperty("java.version")
    "Versions: Rika: #{Rika::VERSION}, Tika: #{Rika.tika_version}, Java: #{java_version}"
  end

  # Process the command line arguments to find URLs and file specifications
  # @return [Array<Array,Hash>] [targets, issues] where targets is an array of valid URLs and filespecs
  #   and issues is a hash of categories to arrays of problematic targets
  def process_args_for_targets
    targets = []
    issues = Hash.new { |hash, key| hash[key] = [] }

    args.each do |arg|
      if arg.include?('://') 
        if File.exist?(arg)
          # Files containing "://" are highly unusual in normal filesystems.
          # This is a defensive check to prevent misinterpreting valid files as URLs
          # just because they contain URL-like patterns, which could happen in test
          # environments or with specially crafted filenames.
          issues[:file_with_url_characters] << arg
        else
          # Otherwise treat it as a URL candidate
          process_url_candidate(arg, targets, issues)
        end
      else
        process_filespec_candidate(arg, targets, issues)
      end
    end
    
    [targets, issues]
  end

  # Determines if a string looks like a URL based on the presence of "://"
  # @param [String] arg string to check
  # @return [Boolean] true if the string appears to be a URL
  def looks_like_url?(arg)
    arg.include?('://')
  end

  # Process a candidate URL
  # @param [String] arg the URL to process
  # @param [Array] targets array to add valid URLs to
  # @param [Hash] issues hash to collect issues
  # @return [void]
  def process_url_candidate(arg, targets, issues)
    begin
      uri = URI.parse(arg)
      if ['http', 'https'].include?(uri.scheme.downcase)
        targets << arg
      else
        issues[:bad_url_scheme] << arg
      end
    rescue URI::InvalidURIError
      issues[:invalid_url] << arg
    end
  end

  # Process a candidate file specification
  # @param [String] arg the filespec to process
  # @param [Array] targets array to add valid filespecs to
  # @param [Hash] issues hash to collect issues
  # @return [void]
  def process_filespec_candidate(arg, targets, issues)
    matching_filespecs = Dir.glob(arg)
    
    if matching_filespecs.empty?
      issues[:non_existent_file] << arg
      return
    end
    
    matching_filespecs.each do |file|
      if File.symlink?(file)
        issues[:is_symlink_wont_process] << file
      elsif File.directory?(file)
        # ignore
      elsif File.empty?(file)
        issues[:empty_file] << file
      else
        targets << file
      end
    end
  end
end
