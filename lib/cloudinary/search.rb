class Cloudinary::Search
  SORT_BY    = :sort_by
  AGGREGATE  = :aggregate
  WITH_FIELD = :with_field
  KEYS_WITH_UNIQUE_VALUES = [SORT_BY, AGGREGATE, WITH_FIELD].freeze

  def initialize
    @query_hash = {
      SORT_BY    => {},
      AGGREGATE  => {},
      WITH_FIELD => {}
    }
  end

  ## implicitly generate an instance delegate the method
  def self.method_missing(method_name, *arguments)
    instance = new
    instance.send(method_name, *arguments)
  end

  def expression(value)
    @query_hash[:expression] = value
    self
  end

  def max_results(value)
    @query_hash[:max_results] = value
    self
  end

  def next_cursor(value)
    @query_hash[:next_cursor] = value
    self
  end

  # Sets the `sort_by` field.
  #
  # @param [String] field_name   The field to sort by. You can specify more than one sort_by parameter;
  #                              results will be sorted according to the order of the fields provided.
  # @param [String] dir          Sort direction. Valid sort directions are 'asc' or 'desc'. Default: 'desc'.
  #
  # @return [Cloudinary::Search]
  def sort_by(field_name, dir = 'desc')
    @query_hash[SORT_BY][field_name] = { field_name => dir }
    self
  end

  # The name of a field (attribute) for which an aggregation count should be calculated and returned in the response.
  #
  # You can specify more than one aggregate parameter.
  #
  # @param [String] value  Supported values: resource_type, type, pixels (only the image assets in the response are
  #                        aggregated), duration (only the video assets in the response are aggregated), format, and
  #                        bytes. For aggregation fields without discrete values, the results are divided into 
  #                        categories.
  # @return [Cloudinary::Search]
  def aggregate(value)
    @query_hash[AGGREGATE][value] = value
    self
  end

  # The name of an additional asset attribute to include for each asset in the response.
  #
  # @param [String] value Possible value: context, tags, and for Tier 2 also image_metadata, and image_analysis.
  #
  # @return [Cloudinary::Search]
  def with_field(value)
    @query_hash[WITH_FIELD][value] = value
    self
  end

  # Returns the query as an hash.
  #
  # @return [Hash]
  def to_h
    @query_hash.each_with_object({}) do |(key, value), query|
      next if value.nil? || ((value.is_a?(Array) || value.is_a?(Hash)) && value.blank?)

      query[key] = KEYS_WITH_UNIQUE_VALUES.include?(key) ? value.values : value
    end
  end

  def execute(options = {})
    options[:content_type] = :json
    uri = 'resources/search'
    Cloudinary::Api.call_api(:post, uri, to_h, options)
  end
end
