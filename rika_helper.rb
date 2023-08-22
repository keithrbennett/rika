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

# Add shortuct to Rika.parse.
def pa(resource)
  Rika.parse(resource)
end

# Add abbreviated aliases for the ParseResult class methods.
class ParseResult
  alias_method :c, :content
  alias_method :m, :metadata
  alias_method :l, :language
  alias_method :i, :input_type
  alias_method :d, :data_source
  alias_method :t, :content_type
  alias_method :j, :metadata_java
end