
# Rika

Rika is a [JRuby](https://www.jruby.org) wrapper for the [Apache Tika](http://tika.apache.org/) Java library, which extracts text and metadata from files and resources of [many different formats](https://tika.apache.org/1.24.1/formats.html).

_Caution: This gem only works with [JRuby](https://www.jruby.org)._

Rika currently supports some basic and commonly used functions of Tika. Future development may add Ruby support for more Tika functionality, and perhaps a command line interface as well. See the [Other Tika Resources](#other-tika-resources) section for alternatives to Rika that may suit more demanding needs.

[![Code Climate](https://codeclimate.com/github/keithrbennett/rika.png)](https://codeclimate.com/github/keithrbennett/rika)
[![Build Status](https://travis-ci.org/keithrbennett/rika.png?branch=master)](https://travis-ci.org/keithrbennett/rika)

## Usage

For a quick start with the simplest use cases, the following functions are provided to get what you need in a single function call, for your convenience:

```ruby
require 'rika'

content           = Rika.parse_content('x.pdf')    # string containing all content text
metadata          = Rika.parse_metadata('x.pdf')   # hash containing the document metadata
content, metadata = Rika.parse_content_and_metadata('x.pdf')   # both of the above
```

A URL can be used instead of a filespec wherever a data source is specified:

```ruby
content, metadata = Rika.parse_content_and_metadata('https://github.com/keithrbennett/rika')
```

For other use cases and finer control, you can work directly with the Rika::Parser object:

```ruby
require 'rika'

parser = Rika::Parser.new('x.pdf')

# Return the content of the document:
parser.content 

# Return the metadata of the document:
parser.metadata 

# Return the media type for the document, e.g. "application/pdf":
parser.media_type 

# Return only the first 10000 chars of the content:
parser = Rika::Parser.new('x.pdf', 10000)
parser.content # 10000 first chars returned

# Return content from URL
parser = Rika::Parser.new('http://example.com/x.pdf', 200)
parser.content

# Return the language for the content
parser = Rika::Parser.new('german-document.pdf')
parser.language
=> "de"

# Check whether the language identification is certain enough to be trusted
parser.language_is_reasonably_certain?
	
```

#### Simple Command Line Use

Since Ruby supports the `-r` option to require a library, and the `-e` option to evaluate a string of code, you can easily do simple parsing on the command line, such as:

```
ruby -r rika -e 'puts Rika.parse_content("x.pdf")'
```

You could also parse the metadata and output it as JSON as follows:

```
ruby -r rika -r json -e 'puts Rika.parse_metadata("x.pdf").to_json'
```

If you want to get both content and metadata in JSON format, this would do that:

```
ruby -r rika -r json -e 'c,m = Rika.parse_content_and_metadata("tw.pdf"); puts({ c: c, m: m }.to_json)'
```

Using the [rexe](https://github.com/keithrbennett/rexe) gem, that can be made much more concise:

```
rexe -r rika -oj 'c,m = Rika.parse_content_and_metadata("x.pdf"); { c: c, m: m }'
```

...and changing the `-oj` option gives you access to other output formats such as "Pretty JSON", YAML, and AwesomePrint (a very human readable format).
 

## Installation

Add this line to your application's Gemfile. Use `gem` or `jgem` depending on your JRuby installation:

    gem 'rika' # or: jgem 'rika'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rika  # or: jgem install rika

## Other Tika Resources

* For more sophisticated use of Tika, you can use the Tika jar file directly in your JRuby code. After installing the `rika` gem, the Tika jar file will be located in `$GEM_HOME/gems/rika-[rika-version]-java/target/dependency/tika-core-[tika-version].jar`. 

* Tika also provides another jar file containing a RESTful server that you can run on the command line. You can download this server jar from http://tika.apache.org/download.html. 
 See the "Running the Tika Server as a Jar file" section of https://cwiki.apache.org/confluence/display/TIKA/TikaServer for more information.

* @chrismattman and others have provided a [Python library and CLI](https://github.com/chrismattmann/tika-python) that interfaces with the Tika server. 

* A general Tika wiki is at https://cwiki.apache.org/confluence/display/tika.


## Credits

Richard Nyström (@ricn) is the original author of Rika, but has not been able to maintain it since 2015. In July 2020, Richard transferred the project to Keith Bennett (@keithrbennett), who had made made some contributions back in 2013.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
