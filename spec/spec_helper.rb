require 'rexml/parsers/ultralightparser'
require 'rspec/version'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  unless RSpec::Version::STRING.match( /^3/)
    config.treat_symbols_as_metadata_keys_with_true_values = true
  end
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding :delete_all => true
end

# Create a regexp with the given tag name.
# @param [String or Symbol] tag tag name (e.g. `img`)
# @return [Regexp] the regular expression to match the tag
def html_tag_matcher( tag)
  /<#{tag}([\s]+([-[:word:]]+)[\s]*\=\s*\"([^\"]*)\")*\s*>.*<\s*\/#{tag}\s*>/
end

def valid_tag(tag)
  parser = REXML::Parsers::UltraLightParser.new( tag)
  parser.parse[0]
end

def attributes(tag)
  valid_tag(tag)[3]
end

def children(tag)
  valid_tag(tag)[4..-1]
end

class TagHelper
  attr_accessor :name, :attributes, :children
  def initialize(element)
    element = valid_tag(element) unless element.is_a? Array
    @name = element[2]
    @attributes = element[3]
    @children = element[4..-1].map {|c | TagHelper.new c}

  end

  def [] symbol
    attributes[symbol.to_s]
  end

end