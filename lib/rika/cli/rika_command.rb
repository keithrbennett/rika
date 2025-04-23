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
  attr_reader :args, :bad_resources, :help_text, :metadata_formatter, :options, :targets, :text_formatter

  # @param [Array<String>] args command line arguments; default to ARGV but may be overridden for testing
  def initialize(args = ARGV)
    # Dup the array in case it has been frozen. The array will be modified later when options are parsed
    # and removed, and when directories are removed, so this array should not be frozen.
    @args = args.dup
    @bad_resources = Hash.new { |hash, key| hash[key] = [] }

  end

  # Main method and entry point for this class' work.
  # @return [Integer] exit code (0 for success, non-zero for errors)
  def call
    prepare
    report_and_exit_if_no_targets_specified
    if options[:as_array]
      puts result_array_output
    else
      targets.each do |target| 
        result = parse_target(target)
        puts single_document_output(target, result) unless result == :error
      end
    end

    # Report any resources that failed
    total_bad_resources = @bad_resources.values.flatten.size
    unless total_bad_resources.zero?
      require 'yaml'
      $stderr.puts("\n#{total_bad_resources} resources could not be processed:")
      $stderr.puts(@bad_resources.to_yaml)
    end

    total_bad_resources.zero? ? 0 : 1
  end


  # Prepares to run the parse. This method is separate from #call so that it can be called from tests.
  # @return [void]
  private def prepare
    @options, @targets, @help_text = ArgsParser.call(args)
    set_output_formats
  end

  # Sets the output format(s) based on the command line options.
  # Exits with error message if format is invalid.
  # @return [void]
  private def set_output_formats
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
  private def result_hash(result)
    h = {}
    h['source']   = result.metadata['rika:data-source'] if options[:source]
    h['metadata'] = result.metadata                     if options[:metadata]
    h['text']     = result.content                      if options[:text]
    h
  end

  # Outputs the source file or URL in the form of:
  # -------------------------------------------------------------------------------
  # Source: path/to/file.ext
  # -------------------------------------------------------------------------------
  # @param [String] source document source identifier
  # @return multiline string as displayed above
  private def source_output_string(source)
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
  private def single_document_output(target, result)
    if options[:metadata] && options[:text] && %w[jj JJ yy].include?(options[:format])
      metadata_formatter.(result_hash(result))
    else
      sio = StringIO.new
      sio << source_output_string(target)                 if options[:source]
      sio << metadata_formatter.(result.metadata) << "\n" if options[:metadata]
      sio << text_formatter.(result.content) << "\n"      if options[:text]
      sio.string
    end
  end

  # Parses a target and returns the result. On error, accumulates the error in the @bad_resources hash.
  # @param [String] target string identifying the target document
  # @return [ParseResult] the parse result
  def parse_target(target)
    exception = nil
    result = :error # default to error, overridden if successful
    begin
      result = Rika.parse(target, max_content_length: max_content_length, key_sort: options[:key_sort])
    rescue java.net.UnknownHostException => e
      exception = e
      bad_resources[:unknown_host] << target
    rescue IOError, java.io.IOException => e
      exception = e
      bad_resources[:io_error] << target
    rescue ArgumentError => e
      exception = e
      bad_resources[:invalid_input] << target
    end

    $stderr.puts("#{exception.class} processing '#{target}': #{exception.message}") if exception && options[:verbose]
$stderr.puts(exception)
    result
  end


  # Parses the documents and outputs the result of the parse to stdout as an array of hashes.
  # Outputting as an array necessitates that the metadata and text formatters be the same
  # (otherwise the output would be invalid, especially with JSON or YAML).
  # Therefore, the metadata formatter is arbitrarily selected to be used by both.
  # @return [String] the string representation of the result of parsing the documents
  private def result_array_output
    results = targets.map { |target| result_hash(parse_target(target)) }
    output_hashes = results.reject { |hash| hash[:error] }

    # Either the metadata or text formatter will do, since they will necessarily be the same formatter.
    metadata_formatter.call(output_hashes)
  end

  # Tika offers a max_content_length option, but it is not exposed in Rika.
  # Instead it is used only to enable or disable the entire text output.
  private def max_content_length
    options[:text] ? -1 : 0
  end

  # Prints message and help and exits if no targets are specified.
  # The exit code is zero because this may not necessarily be an error, and we wouldn't want to
  # be the cause of aborting a script. The documents specified as input to this command may be
  # dynamically generated by a script, and the script may not want to abort if no documents are
  # generated.
  # @return [void] or exits
  private def report_and_exit_if_no_targets_specified
    if targets.empty?
      $stderr.puts(%q{No valid targets specified. Run with '-h' option for help.})
      exit 0
    end
    nil
  end
end
