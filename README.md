# Rika

A JRuby wrapper for Apache Tika to extract text and metadata from various file formats.

More information about Apache Tika can be found here: http://tika.apache.org/

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
```ruby
	require 'rika'

	parser = Rika::Parser.new('document.pdf')

	# Return the content of the document:
	parser.content 

	# Return the metadata field title if it exists:
	parser.metadata["title"] if parser.metadata_exists?("title") 

	# Return all the available metadata keys that can be read from the document
	parser.available_metadata

	# Return only the first 10000 chars of the content:
	parser = Rika::Parser.new('document.pdf', 10000)
	parser.content # 10000 first chars returned

	# Return content from URL (only in master)
	parser = Rika::Parser.new('http://www.exampleurl.com/example.pdf')
	parser.content	
```
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
