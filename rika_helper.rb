# frozen_string_literal: true

# Defines some shortcuts for ad-hoc work with Rika.
#
# Can be used with the `irb`/`jirb` or `pry` (https://github.com/pry/pry) interactive shells:
# `pry -r rika_helper.rb`
#
# Can be used with the `rexe` command line executor (https://github.com/keithrbennett/rexe):
# rexe -r ./rika_helper.rb # e.g., add: `-oa 'm "x.pdf"'` to output metadata w/AwesomePrint
#
# or plain Ruby:
# ruby -r ./rika_helper -r awesome_print -e 'ap m("x.pdf")'

require 'rika'

def c(resource)
  Rika.parse_content(resource)
end

def m(resource)
  Rika.parse_metadata(resource)
end

def cm(resource)
  Rika.parse_content_and_metadata(resource)
end

def cmh(resource)
  Rika.parse_content_and_metadata_as_hash(resource)
end

def mj(resource); m(resource).to_json                      ; end
def mJ(resource); JSON.pretty_generate(m(resource))        ; end
def my(resource); m(resource).to_yaml                      ; end
def my(resource); require 'awesome_print'; m(resource).ai  ;end

def cmj(resource); c(resource).to_json;               end
def cmJ(resource); JSON.pretty_generate(c(resource)); end
def cmy(resource); c(resource).to_yaml              ; end
def cma(resource); require 'awesome_print'; c,m = cm(resource); { content: c, metadata: m }; end
