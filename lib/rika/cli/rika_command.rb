# frozen_string_literal: true

require 'awesome_print'
require 'optparse'
require 'rika'
require 'rika/formatters'
require 'rika/cli/args_parser'
require 'stringio'

# This command line application enables the parsing of documents on the command line.
# Syntax is:
#   rika [options] <file or url> [...file or url...]
# Run with -h or --help option for more details.
#
# Defaults to outputting both content (text) and metadata,
# but the -t and -m flags can be used to enable or suppress either.
# Supports output formats of JSON, Pretty JSON, YAML, Awesome Print, to_s, and inspect (see Formatters class).
class RikaCommand
  attr_reader :args, :bad_targets, :help_text, :metadata_formatter, :options, :targets, :text_formatter

  # @param [Array<String>] args command line arguments; default to ARGV but may be overridden for testing
  def initialize(args = ARGV)
    # Dup the array in case it has been frozen. The array will be modified later when options are parsed
    # and removed, and when directories are removed, so this array should not be frozen.
    @args = args.dup
    @bad_targets = Hash.new { |hash, key| hash[key] = [] }
  end

  # Main method and entry point for this class' work.
  # @return [Integer] exit code (0 for success, non-zero for errors)
  def call
    prepare
    report_and_exit_if_no_targets_specified
    process_targets
    report_bad_targets
    bad_targets.values.flatten.empty? ? 0 : 1
  end

  private

  # Prepares to run the parse. This method is separate from #call so that it can be called from tests.
  # @return [void]
  def prepare
    @options, @targets, @help_text, issues = ArgsParser.call(args)
    
    # Add any issues from ArgsParser to our bad_targets
    issues.each do |issue_type, issue_targets|
      issue_targets.each { |target| bad_targets[issue_type] << target }
    end
    
    set_output_formats
  end

  # Process all targets based on options
  # @return [void]
  def process_targets
    if options[:as_array]
      puts result_array_output
    else
      targets.each do |target| 
        result = parse_target(target)
        puts single_document_output(target, result) unless result == :error
      end
    end
  end

  # Report any targets that failed to process
  # @return [void]
  def report_bad_targets
    total_bad_targets = bad_targets.values.flatten.size
    return if total_bad_targets.zero?

    require 'yaml'
    $stderr.puts("\n#{total_bad_targets} targets could not be processed:")
    $stderr.puts(bad_targets.to_yaml)
  end

  # Sets the output format(s) based on the command line options.
  # Exits with error message if format is invalid.
  # @return [void]
  def set_output_formats
    format = options[:format]
    @metadata_formatter = Rika::Formatters.get(format[0])
    @text_formatter     = Rika::Formatters.get(format[1])
    nil
  rescue KeyError
    $stderr.puts "Invalid format: #{format}"
    $stderr.puts help_text
    exit 1
  end

  # Converts a ParseResult to a hash containing the selected pieces of data.
  # @param [ParseResult] result the parse result
  # @return [Hash] the hash containing the selected pieces of data
  def result_hash(result)
    {}.tap do |h|
      h['source']   = result.metadata['rika:data-source'] if options[:source]
      h['metadata'] = result.metadata                     if options[:metadata]
      h['text']     = result.content                      if options[:text]
    end
  end

  # Outputs the source file or URL in the form of:
  # -------------------------------------------------------------------------------
  # Source: path/to/file.ext
  # -------------------------------------------------------------------------------
  # @param [String] source document source identifier
  # @return multiline string as displayed above
  def source_output_string(source)
    <<~STRING
      -------------------------------------------------------------------------------
      Source: #{source}
      -------------------------------------------------------------------------------
    STRING
  end

  # Builds the string representation of the result of parsing a single document
  # @param [String] target the target document
  # @param [ParseResult] result the parse result
  # @return [String] the string representation of the result of parsing a single document
  def single_document_output(target, result)
    if should_use_single_formatter?(options[:format])
      metadata_formatter.(result_hash(result))
    else
      build_output_string(target, result)
    end
  end

  # Determines if we should use a single formatter for both metadata and text
  # @param [String] format the format string
  # @return [Boolean] true if we should use a single formatter
  def should_use_single_formatter?(format)
    options[:metadata] && options[:text] && %w[jj JJ yy].include?(format)
  end

  # Builds an output string with multiple sections
  # @param [String] target the target document
  # @param [ParseResult] result the parse result
  # @return [String] formatted output string
  def build_output_string(target, result)
    StringIO.new.tap do |sio|
      sio << source_output_string(target)                 if options[:source]
      sio << metadata_formatter.(result.metadata) << "\n" if options[:metadata]
      sio << text_formatter.(result.content) << "\n"      if options[:text]
    end.string
  end

  # Parses a target and returns the result. On error, accumulates the error in the @bad_targets hash.
  # @param [String] target string identifying the target document
  # @return [ParseResult] the parse result
  def parse_target(target)
    Rika.parse(target, max_content_length: max_content_length, key_sort: options[:key_sort])
  rescue java.net.UnknownHostException => e
    handle_parse_error(e, target, :unknown_host)
  rescue IOError, java.io.IOException => e
    handle_parse_error(e, target, :io_error)
  rescue ArgumentError => e
    handle_parse_error(e, target, :invalid_input)
  end

  # Handle parse errors consistently
  # @param [Exception] exception the exception that occurred
  # @param [String] target the target being processed
  # @param [Symbol] error_type the type of error that occurred
  # @return [Symbol] :error to indicate an error occurred
  def handle_parse_error(exception, target, error_type)
    bad_targets[error_type] << target
    $stderr.puts("#{exception.class} processing '#{target}': #{exception.message}") if options[:verbose]
    :error
  end

  # Parses the documents and outputs the result of the parse to stdout as an array of hashes.
  # Outputting as an array necessitates that the metadata and text formatters be the same
  # (otherwise the output would be invalid, especially with JSON or YAML).
  # Therefore, the metadata formatter is arbitrarily selected to be used by both.
  # @return [String] the string representation of the result of parsing the documents
  def result_array_output
    results = targets \
      .map { |target| parse_target(target) } \
      .reject { |target| target == :error }
    output_hashes = results.map { |result| result_hash(result) }

    # Either the metadata or text formatter will do, since they will necessarily be the same formatter.
    metadata_formatter.call(output_hashes)
  end

  # Tika offers a max_content_length option, but it is not exposed in Rika.
  # Instead it is used only to enable or disable the entire text output.
  def max_content_length
    options[:text] ? -1 : 0
  end

  # Prints message and help and exits if no targets are specified.
  # The exit code is zero because this may not necessarily be an error, and we wouldn't want to
  # be the cause of aborting a script. The documents specified as input to this command may be
  # dynamically generated by a script, and the script may not want to abort if no documents are
  # generated.
  # @return [void] or exits
  def report_and_exit_if_no_targets_specified
    if targets.empty?
      $stderr.puts(%q{No valid targets specified. Run with '-h' option for help.})
      exit 0
    end
    nil
  end
end

