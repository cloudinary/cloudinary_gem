# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding :delete_all => true
end

# Create a regexp with the given tag name.
# @param [String or Symbol] tag tag name (e.g. `img`)
# @return [Regexp] the regular expression to match the tag
def html_self_closing_tag_matcher(tag)
  /<#{tag}([\s]+[-[:word:]]+[\s]*\=\s*\"[^\"]*\")*\s*\s*\/>*./
end
