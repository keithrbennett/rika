# Rika

A JRuby wrapper for Apache Tika to extract text and metadata from various file formats.

## Installation

Add this line to your application's Gemfile:

    gem 'rika'

Remember that this gem only works on JRuby.

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rika

## Usage

Something like this:

parser = Rika::Parser.new(filename)

parser.content # returns all the parsed content

parser.metadata["title"] # returns the title metadata if available. 

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
