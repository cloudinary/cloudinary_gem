# Copyright Cloudinary
require 'digest/sha1'
require 'zlib'
require 'uri'
require 'aws_cf_signer'

class Cloudinary::Utils
  # @deprecated Use Cloudinary::SHARED_CDN
  SHARED_CDN = Cloudinary::SHARED_CDN
  DEFAULT_RESPONSIVE_WIDTH_TRANSFORMATION = {:width => :auto, :crop => :limit}

  # Warning: options are being destructively updated!
  def self.generate_transformation_string(options={})
    if options.is_a?(Array)
      return options.map{|base_transformation| generate_transformation_string(base_transformation.clone)}.join("/")
    end
    # Symbolize keys
    options.keys.each do |key|
      options[(key.to_sym rescue key)] = options.delete(key)
    end
    
    responsive_width = config_option_consume(options, :responsive_width) 
    size = options.delete(:size)
    options[:width], options[:height] = size.split("x") if size
    width = options[:width]
    width = width.to_s if width.is_a?(Symbol)
    height = options[:height]
    has_layer = options[:overlay].present? || options[:underlay].present?

    crop = options.delete(:crop)
    angle = build_array(options.delete(:angle)).join(".")

    no_html_sizes = has_layer || angle.present? || crop.to_s == "fit" || crop.to_s == "limit" || crop.to_s == "lfill"
    options.delete(:width) if width && (width.to_f < 1 || no_html_sizes || width == "auto" || responsive_width)
    options.delete(:height) if height && (height.to_f < 1 || no_html_sizes || responsive_width)

    width=height=nil if crop.nil? && !has_layer && width != "auto"

    background = options.delete(:background)
    background = background.sub(/^#/, 'rgb:') if background

    color = options.delete(:color)
    color = color.sub(/^#/, 'rgb:') if color

    base_transformations = build_array(options.delete(:transformation))
    if base_transformations.any?{|base_transformation| base_transformation.is_a?(Hash)}
      base_transformations = base_transformations.map do
        |base_transformation|
        base_transformation.is_a?(Hash) ? generate_transformation_string(base_transformation.clone) : generate_transformation_string(:transformation=>base_transformation)
      end
    else
      named_transformation = base_transformations.join(".")
      base_transformations = []
    end

    effect = options.delete(:effect)
    effect = Array(effect).flatten.join(":") if effect.is_a?(Array) || effect.is_a?(Hash)

    border = options.delete(:border)
    if border.is_a?(Hash)
      border = "#{border[:width] || 2}px_solid_#{(border[:color] || "black").sub(/^#/, 'rgb:')}"
    elsif border.to_s =~ /^\d+$/ # fallback to html border attribute
      options[:border] = border
      border = nil
    end
    flags = build_array(options.delete(:flags)).join(".")
    dpr = config_option_consume(options, :dpr)

    if options.include? :offset
      options[:start_offset], options[:end_offset] = split_range options.delete(:offset)
    end

    params = {
      :a   => angle,
      :b   => background,
      :bo  => border,
      :c   => crop,
      :co  => color,
      :dpr => dpr,
      :e   => effect,
      :fl  => flags,
      :h   => height,
      :t   => named_transformation,
      :w   => width
    }
    {
      :ac => :audio_codec,
      :br => :bit_rate,
      :cs => :color_space,
      :d  => :default_image,
      :dl => :delay,
      :dn => :density,
      :du => :duration,
      :eo => :end_offset,
      :f  => :fetch_format,
      :g  => :gravity,
      :l  => :overlay,
      :o  => :opacity,
      :p  => :prefix,
      :pg => :page,
      :q  => :quality,
      :r  => :radius,
      :af => :audio_frequency,
      :so => :start_offset,
      :u  => :underlay,
      :vc => :video_codec,
      :vs => :video_sampling,
      :x  => :x,
      :y  => :y,
      :z  => :zoom
    }.each do
      |param, option|
      params[param] = options.delete(option)
    end

    params[:vc] = process_video_params params[:vc] if params[:vc].present?
    [:so, :eo, :du].each do |range_value|
      params[range_value] = norm_range_value params[range_value] if params[range_value].present?
    end

    transformation = params.reject{|_k,v| v.blank?}.map{|k,v| "#{k}_#{v}"}.sort.join(",")
    raw_transformation = options.delete(:raw_transformation)
    transformation = [transformation, raw_transformation].reject(&:blank?).join(",")
    transformations = base_transformations << transformation
    if responsive_width
      responsive_width_transformation = Cloudinary.config.responsive_width_transformation || DEFAULT_RESPONSIVE_WIDTH_TRANSFORMATION
      transformations << generate_transformation_string(responsive_width_transformation.clone)
    end

    if width.to_s == "auto" || responsive_width
      options[:responsive] = true
    end
    if dpr.to_s == "auto"
      options[:hidpi] = true
    end

    transformations.reject(&:blank?).join("/")
  end

  def self.api_string_to_sign(params_to_sign)
    params_to_sign.map{|k,v| [k.to_s, v.is_a?(Array) ? v.join(",") : v]}.reject{|k,v| v.nil? || v == ""}.sort_by(&:first).map{|k,v| "#{k}=#{v}"}.join("&")
  end

  def self.api_sign_request(params_to_sign, api_secret)
    to_sign = api_string_to_sign(params_to_sign)
    Digest::SHA1.hexdigest("#{to_sign}#{api_secret}")
  end

  # Warning: options are being destructively updated!
  def self.unsigned_download_url(source, options = {})

    type = options.delete(:type)

    options[:fetch_format] ||= options.delete(:format) if type == :fetch
    transformation = self.generate_transformation_string(options)

    resource_type = options.delete(:resource_type)
    version = options.delete(:version)
    format = options.delete(:format)
    cloud_name = config_option_consume(options, :cloud_name) || raise(CloudinaryException, "Must supply cloud_name in tag or in configuration")

    secure = options.delete(:secure)
    ssl_detected = options.delete(:ssl_detected)
    secure = ssl_detected || Cloudinary.config.secure if secure.nil?
    private_cdn = config_option_consume(options, :private_cdn)
    secure_distribution = config_option_consume(options, :secure_distribution)
    cname = config_option_consume(options, :cname)
    shorten = config_option_consume(options, :shorten)
    force_remote = options.delete(:force_remote)
    cdn_subdomain = config_option_consume(options, :cdn_subdomain)
    secure_cdn_subdomain = config_option_consume(options, :secure_cdn_subdomain)
    sign_url = config_option_consume(options, :sign_url)
    secret = config_option_consume(options, :api_secret)
    sign_version = config_option_consume(options, :sign_version) # Deprecated behavior
    url_suffix = options.delete(:url_suffix)
    use_root_path = config_option_consume(options, :use_root_path)

    raise(CloudinaryException, "URL Suffix only supported in private CDN") if url_suffix.present? and not private_cdn

    original_source = source
    return original_source if source.blank?
    if defined?(CarrierWave::Uploader::Base) && source.is_a?(CarrierWave::Uploader::Base)
      resource_type ||= source.resource_type
      type ||= source.storage_type
      source = format.blank? ? source.filename : source.full_public_id
    end
    resource_type ||= "image"
    source = source.to_s
    if !force_remote
      return original_source if (type.nil? || type == :asset) && source.match(%r(^https?:/)i)
      if source.start_with?("/")
        if source.start_with?("/images/")
          source = source.sub(%r(/images/), '')
        else
          return original_source
        end
      end
      @metadata ||= defined?(Cloudinary::Static) ? Cloudinary::Static.metadata : {}
      if type == :asset && @metadata["images/#{source}"]
        return original_source if !Cloudinary.config.static_image_support
        source = @metadata["images/#{source}"]["public_id"]
        source += File.extname(original_source) if !format
      elsif type == :asset
        return original_source # requested asset, but no metadata - probably local file. return.
      end
    end

    resource_type, type = finalize_resource_type(resource_type, type, url_suffix, use_root_path, shorten)
    source, source_to_sign = finalize_source(source, format, url_suffix)

    version ||= 1 if source_to_sign.include?("/") and !source_to_sign.match(/^v[0-9]+/) and !source_to_sign.match(/^https?:\//)
    version &&= "v#{version}"

    transformation = transformation.gsub(%r(([^:])//), '\1/')
    if sign_url
      to_sign = [transformation, sign_version && version, source_to_sign].reject(&:blank?).join("/")
      signature = 's--' + Base64.urlsafe_encode64(Digest::SHA1.digest(to_sign + secret))[0,8] + '--'
    end

    prefix = unsigned_download_url_prefix(source, cloud_name, private_cdn, cdn_subdomain, secure_cdn_subdomain, cname, secure, secure_distribution)
    source = [prefix, resource_type, type, signature, transformation, version, source].reject(&:blank?).join("/")
  end

  def self.finalize_source(source, format, url_suffix)
    source = source.gsub(%r(([^:])//), '\1/')
    if source.match(%r(^https?:/)i)
      source = smart_escape(source)
      source_to_sign = source
    else
      source = smart_escape(URI.decode(source))
      source_to_sign = source
      unless url_suffix.blank?
        raise(CloudinaryException, "url_suffix should not include . or /") if url_suffix.match(%r([\./]))
        source = "#{source}/#{url_suffix}"
      end
      if !format.blank?
        source = "#{source}.#{format}"
        source_to_sign = "#{source_to_sign}.#{format}"
      end
    end
    [source, source_to_sign]
  end

  def self.finalize_resource_type(resource_type, type, url_suffix, use_root_path, shorten)
    type ||= :upload
    if !url_suffix.blank?
      if resource_type.to_s == "image" && type.to_s == "upload"
        resource_type = "images"
        type = nil
      elsif resource_type.to_s == "raw" && type.to_s == "upload"
        resource_type = "files"
        type = nil
      else
        raise(CloudinaryException, "URL Suffix only supported for image/upload and raw/upload")
      end
    end
    if use_root_path
      if (resource_type.to_s == "image" && type.to_s == "upload") || (resource_type.to_s == "images" && type.blank?)
        resource_type = nil
        type = nil
      else
        raise(CloudinaryException, "Root path only supported for image/upload")
      end
    end
    if shorten && resource_type.to_s == "image" && type.to_s == "upload"
      resource_type = "iu"
      type = nil
    end
    [resource_type, type]
  end

  # cdn_subdomain and secure_cdn_subdomain
  # 1) Customers in shared distribution (e.g. res.cloudinary.com)
  #   if cdn_domain is true uses res-[1-5].cloudinary.com for both http and https. Setting secure_cdn_subdomain to false disables this for https.
  # 2) Customers with private cdn
  #   if cdn_domain is true uses cloudname-res-[1-5].cloudinary.com for http
  #   if secure_cdn_domain is true uses cloudname-res-[1-5].cloudinary.com for https (please contact support if you require this)
  # 3) Customers with cname
  #   if cdn_domain is true uses a[1-5].cname for http. For https, uses the same naming scheme as 1 for shared distribution and as 2 for private distribution.
  def self.unsigned_download_url_prefix(source, cloud_name, private_cdn, cdn_subdomain, secure_cdn_subdomain, cname, secure, secure_distribution)
    return "/res#{cloud_name}" if cloud_name.start_with?("/") # For development

    shared_domain = !private_cdn

    if secure
      if secure_distribution.nil? || secure_distribution == Cloudinary::OLD_AKAMAI_SHARED_CDN
        secure_distribution = private_cdn ? "#{cloud_name}-res.cloudinary.com" : Cloudinary::SHARED_CDN
      end
      shared_domain ||= secure_distribution == Cloudinary::SHARED_CDN
      secure_cdn_subdomain = cdn_subdomain if secure_cdn_subdomain.nil? && shared_domain

      if secure_cdn_subdomain
        secure_distribution = secure_distribution.gsub('res.cloudinary.com', "res-#{(Zlib::crc32(source) % 5) + 1}.cloudinary.com")
      end

      prefix = "https://#{secure_distribution}"
    elsif cname
      subdomain = cdn_subdomain ? "a#{(Zlib::crc32(source) % 5) + 1}." : ""
      prefix = "http://#{subdomain}#{cname}"
    else
      host = [private_cdn ? "#{cloud_name}-" : "", "res", cdn_subdomain ? "-#{(Zlib::crc32(source) % 5) + 1}" : "", ".cloudinary.com"].join
      prefix = "http://#{host}"
    end
    prefix += "/#{cloud_name}" if shared_domain

    prefix
  end

  def self.cloudinary_api_url(action = 'upload', options = {})
    cloudinary = options[:upload_prefix] || Cloudinary.config.upload_prefix || "https://api.cloudinary.com"
    cloud_name = options[:cloud_name] || Cloudinary.config.cloud_name || raise(CloudinaryException, "Must supply cloud_name")
    resource_type = options[:resource_type] || "image"
    return [cloudinary, "v1_1", cloud_name, resource_type, action].join("/")
  end

  def self.sign_request(params, options={})
    api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
    params = params.reject{|k, v| self.safe_blank?(v)}
    params[:signature] = Cloudinary::Utils.api_sign_request(params, api_secret)
    params[:api_key] = api_key
    params
  end

  def self.private_download_url(public_id, format, options = {})
    cloudinary_params = sign_request({
        :timestamp=>Time.now.to_i,
        :public_id=>public_id,
        :format=>format,
        :type=>options[:type],
        :attachment=>options[:attachment],
        :expires_at=>options[:expires_at] && options[:expires_at].to_i
      }, options)

    return Cloudinary::Utils.cloudinary_api_url("download", options) + "?" + cloudinary_params.to_query
  end

  def self.zip_download_url(tag, options = {})
    cloudinary_params = sign_request({:timestamp=>Time.now.to_i, :tag=>tag, :transformation=>generate_transformation_string(options)}, options)
    return Cloudinary::Utils.cloudinary_api_url("download_tag.zip", options) + "?" + cloudinary_params.to_query
  end

  def self.signed_download_url(public_id, options = {})
    aws_private_key_path = options[:aws_private_key_path] || Cloudinary.config.aws_private_key_path || raise(CloudinaryException, "Must supply aws_private_key_path")
    aws_key_pair_id = options[:aws_key_pair_id] || Cloudinary.config.aws_key_pair_id || raise(CloudinaryException, "Must supply aws_key_pair_id")
    authenticated_distribution = options[:authenticated_distribution] || Cloudinary.config.authenticated_distribution || raise(CloudinaryException, "Must supply authenticated_distribution")
    @signers ||= Hash.new{|h,k| path, id = k; h[k] = AwsCfSigner.new(path, id)}
    signer = @signers[[aws_private_key_path, aws_key_pair_id]]
    url = Cloudinary::Utils.unsigned_download_url(public_id, {:type=>:authenticated}.merge(options).merge(:secure=>true, :secure_distribution=>authenticated_distribution, :private_cdn=>true))
    expires_at = options[:expires_at] || (Time.now+3600)
    signer.sign(url, :ending => expires_at)
  end

  def self.cloudinary_url(public_id, options = {})
    if options[:type].to_s == 'authenticated' && !options[:sign_url]
      result = signed_download_url(public_id, options)
    else
      result = unsigned_download_url(public_id, options)
    end
    return result
  end

  def self.asset_file_name(path)
    data = Cloudinary.app_root.join(path).read(:mode=>"rb")
    ext = path.extname
    md5 = Digest::MD5.hexdigest(data)
    public_id = "#{path.basename(ext)}-#{md5}"
    "#{public_id}#{ext}"
  end

  # Based on CGI::unescape. In addition does not escape / :
  def self.smart_escape(string)
    string.gsub(/([^a-zA-Z0-9_.\-\/:]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end
  end

  def self.random_public_id
    sr = defined?(ActiveSupport::SecureRandom) ? ActiveSupport::SecureRandom : SecureRandom
    sr.base64(20).downcase.gsub(/[^a-z0-9]/, "").sub(/^[0-9]+/, '')[0,20]
  end

  def self.signed_preloaded_image(result)
    "#{result["resource_type"]}/#{result["type"] || "upload"}/v#{result["version"]}/#{[result["public_id"], result["format"]].reject(&:blank?).join(".")}##{result["signature"]}"
  end

  @@json_decode = false
  def self.json_decode(str)
    if !@@json_decode
      @@json_decode = true
      begin
        require 'json'
      rescue LoadError
        begin
          require 'active_support/json'
        rescue LoadError
          raise LoadError, "Please add the json gem or active_support to your Gemfile"
        end
      end
    end
    defined?(JSON) ? JSON.parse(str) : ActiveSupport::JSON.decode(str)
  end

  def self.build_array(array)
    case array
      when Array then array
      when nil then []
      else [array]
    end
  end

  def self.encode_hash(hash)
    case hash
      when Hash then hash.map{|k,v| "#{k}=#{v}"}.join("|")
      when nil then ""
      else hash
    end
  end

  def self.encode_double_array(array)
    array = build_array(array)
    if array.length > 0 && array[0].is_a?(Array)
      return array.map{|a| build_array(a).join(",")}.join("|")
    else
      return array.join(",")
    end
  end

  IMAGE_FORMATS = %w(bmp png tif tiff jpg jpeg gif pdf ico eps jpc jp2 psd)

  def self.supported_image_format?(format)
    format = format.to_s.downcase
    extension = format =~ /\./ ? format.split('.').last : format
    IMAGE_FORMATS.include?(extension)
  end

  def self.resource_type_for_format(format)
    self.supported_image_format?(format) ? 'image' : 'raw'
  end

  def self.config_option_consume(options, option_name, default_value = nil)
    return options.delete(option_name) if options.include?(option_name)
    return Cloudinary.config.send(option_name) || default_value
  end

  def self.as_bool(value)
    case value
    when nil then nil
    when String then value.downcase == "true" || value == "1"
    when TrueClass then true
    when FalseClass then false
    when Fixnum then value != 0
    when Symbol then value == :true
    else
      raise "Invalid boolean value #{value} of type #{value.class}"
    end
  end

  def self.as_safe_bool(value)
    case as_bool(value)
    when nil then nil
    when TrueClass then 1
    when FalseClass then 0
    end
  end

  def self.safe_blank?(value)
    value.nil? || value == "" || value == []
  end

  private
  def self.number_pattern
    "([0-9]*)\\.([0-9]+)|([0-9]+)"
  end

  def self.offset_any_pattern
    "(#{number_pattern})([%pP])?"
  end

  def self.offset_any_pattern_re
    /((([0-9]*)\.([0-9]+)|([0-9]+))([%pP])?)\.\.((([0-9]*)\.([0-9]+)|([0-9]+))([%pP])?)/
  end

  # Split a range into the start and end values
  def self.split_range(range) # :nodoc:
    case range
    when Range
      [range.first, range.last]
    when String
      range.split ".." if offset_any_pattern_re =~ range
    when Array
      [range.first, range.last]
    else
      nil
    end
  end

  # Normalize an offset value
  # @param [String] value a decimal value which may have a 'p' or '%' postfix. E.g. '35%', '0.4p'
  # @return [Object|String] a normalized String of the input value if possible otherwise the value itself
  def self.norm_range_value(value) # :nodoc:
    offset = /^#{offset_any_pattern}$/.match( value.to_s)
    if offset
      modifier   = offset[5].present? ? 'p' : ''
      value  = "#{offset[1]}#{modifier}"
    end
    value
  end

  # A video codec parameter can be either a String or a Hash.
  #
  # @param [Object] param <code>vc_<codec>[ : <profile> : [<level>]]</code>
  #                       or <code>{ codec: 'h264', profile: 'basic', level: '3.1' }</code>
  # @return [String] <code><codec> : <profile> : [<level>]]</code> if a Hash was provided
  #                   or the param if a String was provided.
  #                   Returns NIL if param is not a Hash or String
  def self.process_video_params(param)
    case param
    when Hash
      video = ""
      if param.has_key? :codec
        video = param[:codec]
        if param.has_key? :profile
          video.concat ":" + param[:profile]
          if param.has_key? :level
            video.concat ":" + param[:level]
          end
        end
      end
      video
    when String
      param
    else
      nil
    end
  end

  def self.deep_symbolize_keys(object)
    case object
    when Hash
      result = {}
      object.each do |key, value|
        key = key.to_sym rescue key
        result[key] = deep_symbolize_keys(value)
      end
      result
    when Array
      object.map{|e| deep_symbolize_keys(e)}
    else
      object
    end
  end

end
