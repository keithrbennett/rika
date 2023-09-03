# frozen_string_literal: true

require 'awesome_print'
require 'optparse'
require 'rika'
require 'rika/formatters'

# This command line application enables the parsing of documents on the command line.
# Syntax is:
#   rika [options] <file or url> [...file or url...]
# Run with -h or --help option for more details.
#
# Defaults to outputting both content (text) and metadata,
# but the -t and -m flags can be used to enable or suppress either.
# Supports output formats of JSON, Pretty JSON, YAML, Awesome Print, to_s, and inspect (see Formatters class).
class RikaCommand

  attr_reader :args, :help_text, :metadata_formatter, :options, :targets, :text_formatter

  # @param [Array<String>] args command line arguments; default to ARGV but may be overridden for testing
  def initialize(args = ARGV)
    # Dup the array in case it has been frozen. The array will be modified later when options are parsed
    # and removed, and when directories are removed, so this array should not be frozen.
    @args = args.dup
  end

  # Run the command line application.
  # @return [void]
  def run
    process_args
    if options[:as_array]
      puts result_array_output
    else
      targets.each do |target|
        result = Rika.parse(target, max_content_length: max_content_length, key_sort: options[:key_sort])
        puts single_document_output(target, result)
      end
    end
    nil
  end

  # Sets the output format(s) based on the command line options.
  # Exits with error message if format is invalid.
  # @return [void]
  private def set_output_formats
    begin
      format = options[:format]
      @metadata_formatter = Rika::Formatters.get(format[0])
      @text_formatter     = Rika::Formatters.get(format[1])
      nil
    rescue KeyError
      $stderr.puts "Invalid format: #{format}\n\n"
      $stderr.puts help_text
      exit 1
    end
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

  # Builds the string representation of the result of parsing a single document
  # @param [String] target the target document
  # @param [ParseResult] result the parse result
  # @return [String] the string representation of the result of parsing a single document
  private def single_document_output(target, result)
    if options[:metadata] && options[:text] && %w[jj JJ yy].include?(options[:format])
      metadata_formatter.(result_hash(result))
    else
      sio = StringIO.new
      sio << "Source: #{target}\n"                        if options[:source]
      sio << metadata_formatter.(result.metadata) << "\n" if options[:metadata]
      sio << text_formatter.(result.content) << "\n"      if options[:text]
      sio.string
    end
  end

  # Parses the documents and outputs the result of the parse to stdout as an array of hashes.
  # Outputting as an array necessitates that the metadata and text formatters be the same
  # (otherwise the output would be invalid, especially with JSON or YAML).
  # Therefore, the metadata formatter is arbitrarily selected to be used by both.
  # @return [String] the string representation of the result of parsing the documents
  private def result_array_output
    output_hashes = targets.map do |target|
      result = Rika.parse(target, max_content_length: max_content_length, key_sort: options[:key_sort])
      result_hash(result)
    end

    # Either the metadata or text formatter will do, since they will necessarily be the same formatter.
    metadata_formatter.call(output_hashes)
  end

  # Prints message and help if no targets are specified.
  # @return [void]
  private def warn_if_no_targets_specified
    if targets.empty?
      $stderr.puts <<~MESSAGE

        No targets specified.

        #{help_text}
      MESSAGE
    end
    nil
  end

  # Parse the command line options into a hash, and remove them from ARGV.
  # @return [Array<Hash,String>] [options, targets, help_string], or exits if help or version requested
  private def parse_command_line
    # Initialize the options hash with default options:
    options = \
      {
        as_array: false,
        format:   'at', # AwesomePrint for metadata, to_s for text content
        metadata: true,
        text:     true,
        source:   true,
        key_sort: true
      }

    prepend_environment_options

    options_parser = \
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

        opts.on('-s', '--[no-]source [FLAG]', TrueClass, 'Document source file or URL') do |v|
          options[:source] = (v.nil? ? true : v)
        end

        opts.on('-a', '--[no-]as-array [FLAG]', TrueClass, 'Output all parsed results as an array (default: false)') do |v|
          options[:as_array] = (v.nil? ? true : v)
        end

        opts.on('-v', '--version', 'Output version') do
          puts versions_string
          exit
        end

        opts.on('-h', '--help', 'Output help') do
          puts opts
          exit
        end
      end

    options_parser.parse!(@args)
    targets = @args.dup.reject { |arg| File.directory?(arg) }.freeze # reject dirs to handle **/* globbing
    targets.map(&:freeze)

    # If only one format letter is specified, use it for both metadata and text.
    options[:format] *= 2 if options[:format].length == 1

    # Ignore and remove extra characters after the first two format characters.
    options[:format] = options[:format][0..1]

    [options, targets, options_parser.help]
  end

  # @return [String] string containing versions of Rika and Tika, with labels
  private def versions_string
    "Versions: Rika: #{Rika::VERSION}, Tika: #{Rika.tika_version}"
  end

  # If the user wants to specify options in an environment variable ("RIKA_OPTIONS"),
  # then this method will insert those options at the beginning of the `args` array.
  private def prepend_environment_options
    env_opt_string = environment_options
    if env_opt_string
      args_to_prepend = Shellwords.shellsplit(env_opt_string)
      args.unshift(args_to_prepend).flatten!
    end
  end

  # Tika offers a max_content_length option, but it is not exposed in Rika.
  # Instead it is used only to enable or disable the entire text output.
  private def max_content_length
    options[:text] ? -1 : 0
  end

  # Process arguments on the command line or passed. Populates @options and @targets.
  private def process_args
    @options, @targets, @help_text = parse_command_line
    warn_if_no_targets_specified
    set_output_formats
  end

  private def environment_options
    ENV['RIKA_OPTIONS'] || ''
  end
end
