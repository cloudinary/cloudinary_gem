require 'rspec'
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

# Create a regexp with the given +tag+ name.
def html_tag_matcher( tag)
  /<#{tag}([\s]+([-[:word:]]+)[\s]*\=\s*\"([^\"]*)\")*\s*>.*<\s*\/#{tag}\s*>/
end

# Represents an HTML tag
class TestTag
  attr_accessor :name, :attributes, :children, :text, :html_string
  # Creates a new +TestTag+ from a given +element+ string
  def initialize(element)
    @html_string = element
    element = valid_tag(element) unless element.is_a? Array
    case element[0]
    when :start_element
      @name = element[2]
      @attributes = element[3]
      @children = (Array(element[4..-1]) || []).map {|c | TestTag.new c}
    when :text
      @text = element[1]
      @name = "text"
      @attributes = []
      @children = []
    end

  end

  # Parses a given +tag+ in string format
  def valid_tag(tag)
    parser = REXML::Parsers::UltraLightParser.new( tag)
    parser.parse[0]
  end

  # Returns attribute named +symbol_or_string+
  def [](symbol_or_string)
    attributes[symbol_or_string.to_s]
  end

  def method_missing(symbol, *args)
    if (m = /children_by_(\w+)/.match(symbol.to_s)) and !args.empty?
      @children.select{ |c| c[m[1]] == args[0]}
    else
      super
    end
  end

  def ==(other)
    case other
    when String
      @text == other
    else
      other.respond_to?( :text) &&
        other.respond_to?( :name) &&
        other.respond_to?( :attributes) &&
        other.respond_to?( :children) &&
        @text == other.text &&
        @name == other.name &&
        @attributes == other.attributes &&
        @children == other.children
    end
  end
end

def test_cloudinary_url(public_id, options, expected_url, expected_options)
  url = Cloudinary::Utils.cloudinary_url(public_id, options)
  expect(url).to eq(expected_url)
  expect(options).to eq(expected_options)
  url
end

TEST_IMAGE_URL = "http://cloudinary.com/images/old_logo.png"