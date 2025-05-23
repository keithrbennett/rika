# Rika

[Rika](https://github.com/keithrbennett/rika) is a [JRuby](https://www.jruby.org) wrapper for
the [Apache Tika](http://tika.apache.org/) Java library, which extracts text and metadata from files and resources
of [many different formats](https://tika.apache.org/3.1.0/formats.html).

Unlike most other tools that access Apache Tika, Rika does so without any networking calls. Instead, Rika and Tika
run in the same process, i.e. the same Java Virtual Machine (JVM).

Rika can be used [as a library in your Ruby code](#usage-in-your-ruby-code) or [on the command line](#command-line-executable-usage) using the provided `rika` executable.

For class and method level documentation, please use [YARD](https://yardoc.org/).
You can `gem install yard`, then run `yard doc` from the project root, 
and then open the `doc/index.html` file in a browser.


### Requirements

* This gem only works with [JRuby](https://www.jruby.org).
* The [Apache Tika](http://tika.apache.org/) jar file must be installed on your system.
  See the [Installation](#installation) section below for more information.

Rika currently supports some basic and commonly used functions of Tika.
Since it runs on JRuby, the Tika library's Java methods can be called directly from Ruby code
for more advanced needs.
See the [Other Tika Resources](#other-tika-resources) section of this document for alternatives to
Rika that may suit more demanding needs.


## Usage in Your Ruby Code

> **⚠️ IMPORTANT:** It is necessary to call `Rika.init` before using Rika.  This is because the loading of the Tika library
has been put in an init method, rather than at load time, so that 'jar file not found or specified' errors 
do not prevent your application from loading. If you forget to call `Rika.init`, you may see seemingly unrelated
error messages.

As a convenience, the `Rika.init` method is called automatically when you call the Rika module methods. However,
if you access other Rika classes and methods, `init` may not have been called yet, so you should call it yourself.

----

The Rika `parse` method returns a `Rika::ParseResult` object that contains the parsed text and
various pieces of metadata.  The `ParseResult` class' main methods are:

* `content` - the parsed text
* `metadata` - a hash of metadata key/value pairs
* `content_type` - the content type of the parsed data, e.g. "text/plain; charset=UTF-8"
* `language` - the language of the parsed data, e.g. "en"
* `data_source` - the data source, either a filespec or a URL

For example:

```ruby
require 'rika'

parse_result = Rika.parse('x.pdf') # returns a Rika::ParseResult object
parse_result.content               # string containing all content text
parse_result.text                  # 'text' is an alias for 'content'
parse_result.metadata              # hash containing the document metadata
parse_result.content_type          # e.g. "application/pdf"
parse_result.language              # e.g. "en"
parse_result.data_source           # e.g. "x.pdf"
```

A URL can be used instead of a filespec wherever a data source is specified:

```ruby
parse_result = Rika.parse('https://github.com/keithrbennett/rika')
```

The Rika module also has the following methods:

```ruby
Rika.language("magnifique") # => "fr"
Rika.tika_version           # => "2.9.0"
```

## Command Line Executable Usage
  
Rika can also be used on the command line using the `rika` executable.  For example, the simplest form is to simply
specify one or more filespecs or URL's as arguments:

```bash
rika x.pdf https://www.google.com
```
  
> [!NOTE]
> If running `rika` produces an error indicating that the JRuby interpreter cannot be found, try preceding it with `jruby`, e.g. `jruby rika x.pdf`.

Here is the help text:

```
Rika v2.2.0 (Tika v3.1.0) - https://github.com/keithrbennett/rika

Usage: rika [options] <file or url> [...file or url...]
Output formats are: [a]wesome_print, [t]o_s, [i]nspect, [j]son), [J] for pretty json, and [y]aml.
If a format contains two letters, the first will be used for metadata, the second for text.
Values for the text, metadata, and as_array boolean options may be specified as follows:
  Enable:  +, true,  yes, [empty]
  Disable: -, false, no, [long form option with no- prefix, e.g. --no-metadata]

IMPORTANT: Always quote wildcard patterns when files might contain special characters:
           - Double quotes: "*.pdf" (allows variable expansion)
           - Single quotes: '*.pdf' (prevents all shell interpretation)
           Use -n/--dry-run to preview command execution and check for issues.

    -f, --format FORMAT              Output format (default: at)
    -m, --[no-]metadata [FLAG]       Output metadata (default: true)
    -t, --[no-]text [FLAG]           Output text (default: true)
    -k, --[no-]key-sort [FLAG]       Sort metadata keys case insensitively (default: true)
    -s, --[no-]source [FLAG]         Output document source file or URL (default: true)
    -a, --[no-]as-array [FLAG]       Output all parsed results as an array (default: false)
    -n, --[no-]dry-run [FLAG]        Show what would be done without executing (default: false)
    -v, --version                    Output software versions
    -h, --help                       Output help
```    

### Outputting Only Metadata or Only Parsed Text

The default setting is to output both metadata and text. To disable either, use the `-m` or `-t` options 
with a disabling flag, e.g. `-m-`, `-m false`, `-m no`, or `--no-metadata` to disable metadata.

### Outputting the Document Source Identifier (Filespec or URL)

There are many times when it is useful to know the source of the document.  For example, if you are processing
a large number of documents, you may want to know which document a particular piece of output came from.

The document source identifier is output by default.  To disable it, use the `-s` option with a disabling flag, e.g. `-s-`,
`-s false`, `-s no`, or `--no-source`.

### Output Formats

The `-f` option can be used to specify the output format.  The default is `at`, which means that the metadata will be
output in awesome_print format, and the text will be output using `to_s` 
(i.e. without any changes to the parsed string).

If a single argument to `-f` is specified, it will be used for both metadata and text.  If two arguments are specified,
the first will be used for metadata and the second for the parsed text.

### Sorting of Metadata Keys

By default, metadata keys will be sorted case insensitively.  To disable this, use the `-k` option 
with a disabling flag, i.e. `-k-`, `-k false`, `-k no`, or `--no-key-sort`.

The case insensitivity is implemented by using `String#downcase`.
This may not sort correctly on some non-English systems.

### Specifying Command Line Options in the RIKA_OPTIONS Environment Variable

If you find yourself using the same options over and over again, you can put them in the `RIKA_OPTIONS` environment 
variable. For example, if the default behavior of sorting keys does not work for your language, you can disable it
for all invocations of the `rika` command by specifying `-k-` in the RIKA_OPTIONS environment variable.

### Using Wildcards for File Specification

Rika now supports in-app expansion of wildcard patterns for file specification. This means you can quote wildcard patterns 
to prevent the shell from expanding them, and Rika will handle the expansion internally:

```bash
# Let Rika handle the expansion (no practical limit on number of files)
rika '**/*.pdf'

# Shell expands wildcards (limited by shell's maximum argument length)
rika **/*.pdf
```

> **⚠️ IMPORTANT:** Always quote wildcard patterns (using either single or double quotes) when they might match files containing special characters!
> 
> When unquoted, the shell may misinterpret filenames containing spaces, $, *, ?, [], (), {}, &, |, <, >, ;,
> backticks, quotes, and other shell metacharacters, causing unpredictable behavior:
>
> ```bash
> # PROBLEMATIC - Shell breaks/misinterprets files with special characters
> rika pdf/*
> 
> # CORRECT - Both single and double quotes work to preserve filenames
> rika "pdf/*"      # Double quotes allow variable expansion within the pattern
> rika 'pdf/*.pdf'  # Single quotes prevent all shell interpretation
> ```
>
> Use the `-n` (dry-run) option to preview how your command will be processed and to check for issues.

This is particularly useful when dealing with large numbers of files, as shell expansion may hit command line length limits.
In-app expansion has no practical limit on the number of files that can be processed.

Supported wildcard patterns:
- `*` - Match any number of characters
- `?` - Match a single character
- `[abc]` - Match one character from the set
- `{a,b,c}` - Match any of the patterns a, b, or c
- `**` - Recursive directory matching (match all files in all subdirectories)

### Dry Run Mode

You can use the `-n` or `--dry-run` option to see what would happen when running a command without actually executing it:

```bash
rika -n -f jy README.md
```

Like other boolean options, dry-run mode can be disabled with various syntax options:
```bash
rika -n- README.md            # Hyphen suffix
rika -n false README.md       # "false" value
rika -n no README.md          # "no" value
rika --no-dry-run README.md   # --no- prefix
```

This will display:
- All the options that would be used, with human-readable descriptions
- A list of files that would be processed
- Any issues that were detected (like non-existent files)

This is useful for:
- Debugging complex commands
- Checking what files would be processed when using wildcards
- Verifying options before running on large sets of files
- Understanding how different options would affect processing

### Machine Readable Data Support

If both metadata and text are output, and the same output format is used for both, and that format is JSON
(plain or "pretty") or YAML, then the output per document will be a single JSON or YAML hash representation
containing both the metadata and the text (whose keys are "metadata" and "text"). This enables piping
the results of multiple documents to a file or to another program that can use it as a data source. 
In addition, when processing multiple files, this streaming approach will be more efficient 
than calling Rika separately for each file, since each invocation of the rika command requires starting up
a Java Virtual Machine.

If the `-a` (`--as-array`) option is specified, then the output will be an array of such hashes, one for each file.
This enables the output to be used as a data source for programs that can process an array of hashes, e.g. for analysis.

For example, here is an example of how to use Rika and [rexe](https://github.com/keithrbennett/rexe]) to get a tally 
of content types for a set of documents, sorted by content type:

```bash
$ rika -t- -s- -fy -a spec/fixtures/* | \
  rexe -iy -oa -mb "map { |r| r['metadata']['Content-Type'] }.tally.sort.to_h"
{
                                                         "application/msword" => 1,
                                                   "application/octet-stream" => 1,
                                                            "application/pdf" => 1,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => 1,
                                                                 "image/jpeg" => 2,
                                             "text/plain; charset=ISO-8859-1" => 1,
                                                  "text/plain; charset=UTF-8" => 6,
                                          "text/x-matlab; charset=ISO-8859-1" => 1
}
```
Here is a breakdown of the above command:

* `rika`
  * `-t-` suppresses the output of text
  * `-s-` suppresses the output of the source identifier
  * `-fy` outputs the data in YAML format.
  * `-a` option causes the output to be an array of hashes, one for each file
* `rexe` 
  * `-iy` indicates that the input is YAML
  * `-oa` indicates that the output should be done using awesome_print/amazing_print
  * `-mb` indicates that all input should be ingested as a single string ("b" for "big string", as opposed to streamed)

* Ruby code passed to `rexe`
  * `map` is called on the array to extract the content type from each parsed document hash
  * `tally` is called on the resulting array to get the count of each content type
  * `sort` is called on the hash to sort it by key (content type) and return an array of 2-element arrays
  * `to_h` is called on the array of 2-element arrays to convert it back to a hash
  
Here is another example that prints out the 5 most common words in all the parsed text, and their counts,
as "pretty" JSON:

```bash
$ rika -m- spec/fixtures/* | \
rexe -in -oJ -mb 'downcase \
  .split \
  .tally \
  .sort_by { |word, count| [-count, word] }
  .first(5) \
  .to_h'

{
  "the": 35,
  "to": 30,
  "woods": 25,
  "i": 25,
  "and": 25
}
```

## Installation

* Install [JRuby](https://www.jruby.org) if you don't already have it. Ruby version managers such as
[rvm](https://rvm.io/) and [rbenv](https://github.com/rbenv) can simplify this process.
* Download the [Apache Tika](http://tika.apache.org/) jar file from
  http://tika.apache.org/download.html (look for the "tika-app" jar file).
  Put it in a place that makes sense for your system, such as `/usr/local/lib`.
* Configure the `TIKA_JAR_FILESPEC` environment variable to point to the Tika jar file.
  For example, if you are using tika-app-2.9.0.jar, and put the jar file in `/opt/jars',
  then the setting of the environment variable should look like this:

  ```bash
  export TIKA_JAR_FILESPEC=/opt/jars/tika-app-2.9.0.jar
  ```

  You can put this in your `.bashrc` or `.zshrc` file to make it persistent.

* Install the gem:

  ```bash
  gem install rika
  ```

  or, if you're using [bundler](https://bundler.io/), add this to your Gemfile:

  ```ruby
  gem 'rika'
  ```

  and then run `bundle install`.
* Verify that it works by running (as an example) `rika -m https://www.github.com`.
  You should see key/value pairs representing the metadata of the Github home page.

This gem has been tested with JRuby managed by rvm.  It should work with other Ruby version managers and
without any version manager at all, but those configurations have not been tested.

## Using the Tika Java Jar File Directly

Rika provides only the most common Tika use cases.  You may want to dig deeper than Rika does into the massive amount
of functionality provided by the Tika library. You can do so by bypassing Rika altogether and using the Tika jar file
directly in your own JRuby code. In addition. Tika provides its own command line application that can be called as, 
for example, `java -jar $TIKA_JAR_FILESPEC --help`. This Tika command line application has finer grained control
over some Tika options, but is missing some conveniences provided by the Rika command line application.

## Other Tika Resources

* The Apache Tika wiki is at https://cwiki.apache.org/confluence/display/tika.

* Tika also provides another jar file containing a RESTful server that you can run on the command line.
  You can download this server jar from http://tika.apache.org/download.html (look for the "tika-server-standard" jar
  file).
  See the "Running the Tika Server as a Jar file" section of https://cwiki.apache.org/confluence/display/TIKA/TikaServer
  for more information.

* @chrismattman and others have provided a ["tika_python" Python library and CLI](https://github.com/chrismattmann/tika-python)
  that interfaces with the Tika server.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgments

Many thanks to the brilliant and dedicated developers who have worked to build Apache Tika since its inception many years ago.

