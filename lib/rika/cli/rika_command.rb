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

  # Run the command line application.
  # @return [void]
  def run
    @options = parse_command_line
    set_output_formats
    ensure_targets_specified
    if @options[:as_array]
      max_length = @options[:text] ? -1 : 0
      results = targets.map { |target| Rika.parse(target, max_length) }
      output_hashes = results.map(&:content_and_metadata_hash)
      puts @metadata_formatter.call(output_hashes)
    else
      targets.each { |target| output_result(target) }
    end
    nil
  end

  # Sets the output format based on the command line options.
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
  private def output_result(target)
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

  # Prints help and exits if no targets are specified.
  # @return [void]
  private def ensure_targets_specified
    if targets.empty?
      puts <<~MESSAGE

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

    options = \
      # Default to outputting both metadata and text:
      {
        metadata: true,
        text: true
      }

    options_parser = \
      OptionParser.new do |opts|
        opts.banner =  <<~BANNER
          Rika v#{Rika::VERSION} (Tika v#{Rika.tika_version}) - https://github.com/keithrbennett/rika

          Usage: rika [options] <file or url> [...file or url...]
          Output formats are: [a]wesome_print, [t]o_s, [i]nspect, [j]son), [J] for pretty json, [y]aml.
          If a format contains two letters, the first will be used for metadata, the second for text.

        BANNER

        format_message = 'Output format (e.g. `-f at`, which is the default'
        opts.on('-f', '--format FORMAT', format_message) do |format|
          options[:format] = format
        end

        opts.on('-m', '--metadata-only', 'Output metadata only') do
          options[:text] = false
        end

        opts.on('-t', '--text-only', 'Output text only') do
          options[:metadata] = false
        end

        opts.on('-a', '--as-array', 'Output all parsed results as an array') do
          options[:as_array] = true
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

    options_parser.parse!
    options[:format] ||= 'at'

    # If only one format letter is specified, use it for both metadata and text.
    options[:format] *= 2 if options[:format].length == 1

    options
  end

  # @return [String] string containing versions of Rika and Tika
  private def versions_string
    "Versions: Rika: #{Rika::VERSION}, Tika: #{Rika.tika_version}"
  end

  # @return [Array<String>] the filespec and/or HTTP targets to be parsed
  private def targets
    ARGV
  end
end
