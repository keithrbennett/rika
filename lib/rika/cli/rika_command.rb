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
# but the -t and -m flags can be used to output only one or the other.
# Supports output formats of JSON, Pretty JSON, YAML, Awesome Print, to_s, and inspect (see Formatters class).
class RikaCommand

  # @param [Array<String>] args command line arguments; default to ARGV but may be overridden for testing
  def initialize(args = ARGV)
    @args = args
  end

  # Run the command line application.
  # @return [void]
  def run
    @options = parse_command_line
    set_output_formats
    ensure_targets_specified
    if @options[:as_array]
      output_result_array
    else
      targets.each { |target| output_single_document_result(target) }
    end
    nil
  end

  # Sets the output format(s) based on the command line options.
  # Exits with error message if format is invalid.
  # @return [void]
  private def set_output_formats
    begin
      format = @options[:format]
      @metadata_formatter = Rika::Formatters.get(format[0])
      @text_formatter     = Rika::Formatters.get(format[1])
      nil
    rescue KeyError
      $stderr.puts "Invalid format: #{format}\n\n"
      $stderr.puts @help_text
      exit 1
    end
  end

  # Outputs the result of the parse to stdout.
  # @return [void]
  private def output_single_document_result(target)
    result = Rika.parse(target)
    # If both metadata and text are requested, and the format is one of the JSON or YAML
    # formats, then output a hash with both metadata and text as keys.
    if @options[:metadata] && @options[:text] && %w[jj JJ yy].include?(@options[:format])
      puts @metadata_formatter.({ 'metadata' => result.metadata, 'text' => result.content })
    else
      puts @metadata_formatter.(result.metadata) if @options[:metadata]
      puts @text_formatter.(result.content) if @options[:text]
    end
    nil
  end

  # Outputs the result of the parse to stdout as an array of hashes.
  private def output_result_array
    max_length = @options[:text] ? -1 : 0
    results = targets.map { |target| Rika.parse(target, max_length) }
    output_hashes = results.map(&:content_and_metadata_hash)
    puts @metadata_formatter.call(output_hashes)
  end

  # Prints help and exits if no targets are specified.
  # @return [void]
  private def ensure_targets_specified
    if targets.empty?
      $stderr.puts <<~MESSAGE

        Please specify a file or URL to parse.

        #{@help_text}
      MESSAGE
      exit
    end
    nil
  end

  # Parse the command line options into a hash, and remove them from ARGV.
  # @return [Hash] options, or exits if help or version requested
  private def parse_command_line
    # Initialize the options hash with default options:
    options = \
      {
        as_array: false,
        format:   'at',
        metadata: true,
        text:     true
      }

    options_parser = \
      OptionParser.new do |opts|
        opts.banner =  <<~BANNER
          Rika v#{Rika::VERSION} (Tika v#{Rika.tika_version}) - https://github.com/keithrbennett/rika

          Usage: rika [options] <file or url> [...file or url...]
          Output formats are: [a]wesome_print, [t]o_s, [i]nspect, [j]son), [J] for pretty json, and [y]aml.
          If a format contains two letters, the first will be used for metadata, the second for text.
          Values for the text, metadata, and as_array boolean options may be specified as follows:
            Enable:  +, true,  yes, [empty]
            Disable: -, false, no, [long form option with no- prefix, e.g. --no-metadata]

        BANNER

        format_message = 'Output format (e.g. `-f at`, which is the default'
        opts.on('-f', '--format FORMAT', format_message) do |format|
          options[:format] = format
        end

        opts.on('-m', '--[no-]metadata [FLAG]', TrueClass, 'Output metadata') do |v|
          options[:metadata] = (v.nil? ? true : v)
        end

        opts.on('-t', '--[no-]text [FLAG]', TrueClass, 'Output text') do |v|
          options[:text] = (v.nil? ? true : v)
        end

        opts.on('-a', '--[no-]as-array [FLAG]', TrueClass, 'Output all parsed results as an array') do |v|
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
    @help_text = options_parser.help

    options_parser.parse!(@args)

    # If only one format letter is specified, use it for both metadata and text.
    options[:format] *= 2 if options[:format].length == 1

    # Ignore and remove extra characters after the first two format characters.
    options[:format] = options[:format][0..1]

    options
  end

  # @return [String] string containing versions of Rika and Tika
  private def versions_string
    "Versions: Rika: #{Rika::VERSION}, Tika: #{Rika.tika_version}"
  end

  # @return [Array<String>] the filespec and/or HTTP targets to be parsed
  private def targets
    @args
  end
end
