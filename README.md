
# (Rika}[https://github.com/keithrbennett/rika]

Rika is a [JRuby](https://www.jruby.org) wrapper for the [Apache Tika](http://tika.apache.org/) Java library, which extracts text and metadata from files and resources of [many different formats](https://tika.apache.org/1.24.1/formats.html).

_Caution: This gem only works with [JRuby](https://www.jruby.org)._

Rika currently supports some basic and commonly used functions of Tika. Future development may add Ruby support for more Tika functionality, and perhaps a command line interface as well. See the [Other Tika Resources](#other-tika-resources) section for alternatives to Rika that may suit more demanding needs.

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
Rika::Parser.new('x.pdf', 10000).content # 10000 first chars returned

# Return content from URL
Rika::Parser.new('http://example.com/x.pdf').content

# Return the language for the content parsed by this parser
Rika::Parser.new('german-document.pdf').language
# => "de"
```

The Rika module also has some useful methods:

```ruby
# Return the language for the content
Rika.language("magnifique")
# => "fr"

Rika.tika_version
# => "2.8.0"

# (also mentioned above:)
content           = Rika.parse_content('x.pdf')    # string containing all content text
metadata          = Rika.parse_metadata('x.pdf')   # hash containing the document metadata
content, metadata = Rika.parse_content_and_metadata('x.pdf')   # both of the above
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

If you want to get both content and metadata in JSON format, these would do that:

```
ruby -r rika -r json -e 'c,m = Rika.parse_content_and_metadata("x.pdf"); puts({ c: c, m: m }.to_json)'
ruby -r rika -r json -e 'c,m = Rika.parse_content_and_metadata("x.pdf"); puts JSON.pretty_generate({ c: c, m: m })'
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

* The Apache Tika wiki is at https://cwiki.apache.org/confluence/display/tika.

* Tika also provides another jar file containing a RESTful server that you can run on the command line. 
You can download this server jar from http://tika.apache.org/download.html (look for the "tika-server-standard" jar file). 
See the "Running the Tika Server as a Jar file" section of https://cwiki.apache.org/confluence/display/TIKA/TikaServer for more information.

* @chrismattman and others have provided a [Python library and CLI](https://github.com/chrismattmann/tika-python) 
that interfaces with the Tika server.

## Credits

Richard Nyström (@ricn) is the original author of Rika, but became unable to continue investing time in it,
so in 2020 he transferred ownership of the project to Keith Bennett (@keithrbennett),
who had made made some contributions back in 2013, and upgraded Rika to version 2 in 2023.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
