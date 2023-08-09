# Rika

[Rika](https://github.com/keithrbennett/rika) is a [JRuby](https://www.jruby.org) wrapper for
the [Apache Tika](http://tika.apache.org/) Java library, which extracts text and metadata from files and resources
of [many different formats](https://tika.apache.org/1.24.1/formats.html).

Rika can be used as a library in your Ruby code, or on the command line.

### Requirements


* This gem only works with [JRuby](https://www.jruby.org)._
* The [Apache Tika](http://tika.apache.org/) jar file must be installed on your system.
  See the [Installation](#installation) section below for more information.


Rika currently supports some basic and commonly used functions of Tika. Future development may add Ruby support for more
Tika functionality. See the [Other Tika Resources](#other-tika-resources) section of this document for alternatives to
Rika that may suit more demanding needs.

## Usage

For a quick start with the simplest use cases, the following functions are provided to get what you need in a single
function call, for your convenience:

```ruby
require 'rika'

parse_result = Rika.parse('x.pdf')  # returns a Rika::ParseResult object
parse_result.content                # string containing all content text
parse_result.metadata               # hash containing the document metadata
parse_result.media_type             # e.g. "application/pdf"
parse_result.language               # e.g. "en"
parse_result.data_source            # e.g. "x.pdf"
```

A URL can be used instead of a filespec wherever a data source is specified:

```ruby
parse_result = Rika.parse('https://github.com/keithrbennett/rika')
```

The Rika module also has some useful methods in addition to its `parse` method:

```ruby
# Return the language for the content
Rika.language("magnifique")
# => "fr"

Rika.tika_version
# => "2.8.0"
```

## Command Line Usage
  
Rika can also be used on the command line using the `rika` executable.  For example, the simplest form is to simply
specify one or more filespecs or URL's as arguments:

```bash
rika x.pdf https://github.com/keithrbennett/rika
```
Here is the help text:

```
Rika v2.0.0-alpha.1 (Tika v2.8.0) - https://github.com/keithrbennett/rika

Usage: rika [options] <file or url> [...file or url...]
Output formats are: [a]wesome_print, [t]o_s, [i]nspect, [j]son), [p]retty json, [y]aml.
If a format contains two letters, the first will be used for metadata, the second for text.

    -f, --format FORMAT              Output format (e.g. `-f at`, which is the default)
    -m, --metadata-only              Output metadata only
    -t, --text-only                  Output text only
    -v, --version                    Output version
    -h, --help                       Output help
```    

### Outputting Only Metadata or Only Parsed Text

The `-m` and `-t` options can be used to output only metadata or text, respectively.  The default is to output both.

### Output Formats

The `-f` option can be used to specify the output format.  The default is `at`, which means that the metadata will be
output in awesome_print format, and the text will be output using `to_s`, as if `puts` were called on it.

If a single argument to `-f` is specified, it will be used for both metadata and text.  If two arguments are specified,
the first will be used for metadata and the second for the parsed text.

### Machine Readable Data Support

If both metadata and text are output, and the same output format is used for both, and that format is JSON
(plain or "pretty") or YAML, then the output will be a single JSON or YAML hash representation containing both
the metadata and the text (whose keys are "metadata" and "text"). This enables piping the results of multiple documents
to a file or to another program that can use it as a data source. In addition, when processing multiple files, 
this streaming approach will be more efficient than calling Rika separately for each file, since each invocation of
the rika command requires starting up a Java Virtual Machine.

If the `-a` (`--as-array`) option is specified, then the output will be an array of such hashes, one for each file.
This enables the output to be used as a data source for programs that can process an array of hashes, e.g. for analysis.

For example, here is an example of how to use Rika and [rexe](https://github.com/keithrbennett/rexe]) to get a tally 
of content types for a set of documents:

```bash
$ rika -m -fy -a spec/fixtures/* | \
  rexe -iy -oa -mb "map { |r| r[:metadata]['Content-Type'] }.tally"
{
                                                  "text/plain; charset=UTF-8" => 6,
                                                         "application/msword" => 1,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => 1,
                                                            "application/pdf" => 1,
                                                                 "image/jpeg" => 2,
                                             "text/plain; charset=ISO-8859-1" => 1,
                                                   "application/octet-stream" => 1
}
```
Here is a breakdown of the above command:

* `rika`
  * `-m` limits the output to metadata (no text)
  * `-fy` outputs the data in YAML format.
  * `-a` option causes the output to be an array of hashes, one for each file
* `rexe` 
  * `-iy` indicates that the input is YAML
  * `-oa` indicates that the output should be done using awesome_print/amazing_print
  * `-mb` indicates that all input should be ingested as a single string ("b" for "big string", as opposed to streamed)

* Ruby code passed to `rexe`
  * `map` is called on the array to extract the content type from each parsed document hash
  * `tally` is called on the resulting array to get the count of each content type

Here is another example that prints out the 5 most common words in all the parsed text, and their counts,
as "pretty" JSON:

```bash
$ rika -t spec/fixtures/* | \
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
}% 
```

## Installation

* Install [JRuby](https://www.jruby.org) if you don't already have it. Ruby version managers such as
[rvm](https://rvm.io/) and [rbenv](https://github.com/rbenv) can simplify this process.
* Download the [Apache Tika](http://tika.apache.org/) jar file from
  http://tika.apache.org/download.html (look for the "tika-app" jar file).
  Put it in a place that makes sense for your system, such as `/usr/local/lib`.
* Configure the `TIKA_JAR_FILESPEC` environment variable to point to the Tika jar file.
  For example, if you are using tika-app-1.24.1.jar, and put the jar file in `/usr/local/lib`,
  then the setting of the environment variable should look like this:

  ```bash
  export TIKA_JAR_FILESPEC=/usr/local/lib/tika-app-1.24.1.jar
  ```

  You can put this in your `.bashrc` or `.zshrc` file to make it permanent.

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

## Other Tika Resources

* The Apache Tika wiki is at https://cwiki.apache.org/confluence/display/tika.

* Tika also provides another jar file containing a RESTful server that you can run on the command line.
  You can download this server jar from http://tika.apache.org/download.html (look for the "tika-server-standard" jar
  file).
  See the "Running the Tika Server as a Jar file" section of https://cwiki.apache.org/confluence/display/TIKA/TikaServer
  for more information.

* @chrismattman and others have provided a [Python library and CLI](https://github.com/chrismattmann/tika-python)
  that interfaces with the Tika server.

## Credits

Richard Nyström (@ricn) is the original author of Rika, but became unable to continue investing time in it,
so in 2020 he transferred ownership of the project to Keith Bennett (@keithrbennett),
who had made made some contributions back in 2013. Keith upgraded Rika to version 2 in 2023.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
