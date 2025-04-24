# frozen_string_literal: true

require 'optparse'
require 'shellwords'
require 'uri'

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
      verbose: false
    }.freeze

  # Parses the command line arguments.
  # Shorthand for ArgsParser.new.call. This call is recommended to protect the caller in case
  # this functionality is repackaged as a Module or otherwise modified.
  # @param [Array] args the command line arguments (overridable for testing, etc.)
  # @return [Array<Hash,String>] [options, targets, help_string],
  #   or exits if help or version requested or no targets specified.
  def self.call(args = ARGV)
    new.call(args)
  end

  # Parses the command line arguments.
  # @param [Array] args the command line arguments (overridable for testing, etc.)
  # @return [Array<Hash,Array,String>] [options, targets, help_string],
  #   or exits if help or version requested or no targets specified.
  def call(args = ARGV)
    @args = args
    @options = DEFAULT_OPTIONS.dup
    prepend_environment_args
    @option_parser = create_option_parser
    option_parser.parse!(args)
    postprocess_format_options
    targets, errors = process_args_for_resources
    if options[:verbose]
      require 'awesome_print'
      puts "Target results:"
      ap({ targets: targets, errors: errors })
    end

    [options, targets, option_parser.help]
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

      opts.on('-v', '--[no-]verbose [FLAG]', TrueClass, 'Enable verbose output (default: false)') do |v|
        options[:verbose] = (v.nil? ? true : v)
      end

      opts.on('-V', '--version', 'Output software versions') do
        puts versions_string
        exit
      end

      opts.on('-h', '--help', 'Output help') do
        puts opts
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
    ENV['RIKA_OPTIONS'] || ''
  end

  # @return [String] string containing versions of Rika and Tika, with labels
  def versions_string
    java_version = Java::java.lang.System.getProperty("java.version")
    "Versions: Rika: #{Rika::VERSION}, Tika: #{Rika.tika_version}, Java: #{java_version}"
  end

  # Process the command line arguments to find URLs and file specifications
  # @return [Array<Array,Hash>] [resources, errors] where resources is an array of valid URLs and filespecs
  #   and errors is a hash of error categories to arrays of problematic resources
  def process_args_for_resources
    resources = []
    errors = Hash.new { |hash, key| hash[key] = [] }

    args.each do |arg|
      if looks_like_url?(arg)
        process_url_candidate(arg, resources, errors)
      else
        process_filespec_candidate(arg, resources, errors)
      end
    end
    [resources, errors]
  end

  # Determines if a string looks like a URL based on the presence of "://"
  # @param [String] arg string to check
  # @return [Boolean] true if the string appears to be a URL
  def looks_like_url?(arg)
    arg.include?('://')
  end

  # Process a candidate URL
  # @param [String] arg the URL to process
  # @param [Array] resources array to add valid URLs to
  # @param [Hash] errors hash to collect errors
  # @return [void]
  def process_url_candidate(arg, resources, errors)
    begin
      uri = URI.parse(arg)
      if ['http', 'https'].include?(uri.scheme.downcase)
        resources << arg
      else
        errors[:bad_url_scheme] << arg
      end
    rescue URI::InvalidURIError
      errors[:invalid_url] << arg
    end
  end

  # Process a candidate file specification
  # @param [String] arg the filespec to process
  # @param [Array] resources array to add valid filespecs to
  # @param [Hash] errors hash to collect errors
  # @return [void]
  def process_filespec_candidate(arg, resources, errors)
    matching_filespecs = Dir.glob(arg)
    matching_filespecs.each do |file|
      if File.symlink?(file)
        errors[:is_symlink_wont_process] << file
      elsif File.directory?(file)
        # ignore
      else
        resources << file
      end
    end
  end
end
