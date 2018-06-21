module Responsive
# Calculate breakpoints for the given configuration
# @param [Object] srcset the srcset configuration parameters
# @return [Array] an array of breakpoints (width)
  def generate_breakpoints(srcset)
    return srcset[:breakpoints] if srcset[:breakpoints].is_a? Array
    min_width, max_width, max_images = [:min_width, :max_width, :max_images].map {|k| srcset[k]}
    unless [min_width, max_width, max_images].all? {|a| a.is_a? Numeric}
      throw 'Either (min_width, max_width, max_images) or breakpoints must be provided to the image srcset attribute'
    end
    if min_width > max_width
      throw 'min_width must be less than max_width'
    end

    if max_images <= 0
      throw 'max_images must be a positive integer'
    elsif max_images === 1
      min_width = max_width
    end
    step_size = ((max_width - min_width).to_f / [max_images - 1, 1].max).ceil
    current = min_width
    breakpoints = []
    while current < max_width do
      breakpoints.push(current)
      current += step_size
    end
    breakpoints.push(max_width)
  end

# Generate a resource URL scaled to the given width
# @param [String] public_id
# @param [Number|String] width
# @param [Object] options
# @return [String] the new resource URL
  def generate_srcset_url(public_id, width, options)
    config_params = Cloudinary::Utils.extract_config_params(options)
    transformation = if options.has_key?(:srcset) && options[:srcset].has_key?(:transformation)
                       options[:srcset][:transformation]
                     else
                       options
                     end
    config_params[:raw_transformation] = Cloudinary::Utils.generate_transformation_string(
        [transformation.clone, {:crop => 'scale', :width => width}].reject(&:blank?))
    config_params.delete :width
    config_params.delete :height
    Cloudinary::Utils.cloudinary_url public_id, config_params
  end

  def generate_srcset_attribute(public_id, options)
    local_options = Cloudinary::Utils.deep_symbolize_keys(options)
    breakpoints = nil
    srcset = (Cloudinary.config.srcset || {}).merge(local_options[:srcset])
    if srcset["useCache"]
      # breakpoints = Cache.get(public_id, options)
      if !breakpoints
        return ''
      end

    else
      breakpoints = generate_breakpoints(srcset)
    end
    if local_options[:type] == 'fetch'
      local_options[:fetch_format] = local_options[:type]
    end

    breakpoints.map {|width| "#{generate_srcset_url(public_id, width, options)} #{width}w"}.join ', '
  end

  def generate_sizes_attribute(options)
    if options.nil?
      ''
    elsif options.is_a? String
      options
    else
      breakpoints = generate_breakpoints(options)
      breakpoints.map{|width| "(max-width: #{width}px) #{width}px"}.join(', ')
    end
  end
end