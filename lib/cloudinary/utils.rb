# Copyright Cloudinary
require 'digest/sha1'
require 'zlib'
require 'aws_cf_signer'

class Cloudinary::Utils
  # @deprecated Use Cloudinary::SHARED_CDN
  SHARED_CDN = Cloudinary::SHARED_CDN  
  
  # Warning: options are being destructively updated!
  def self.generate_transformation_string(options={})
    if options.is_a?(Array)
      return options.map{|base_transformation| generate_transformation_string(base_transformation.clone)}.join("/")
    end
    # Symbolize keys
    options.keys.each do |key|
      options[key.to_sym] = options.delete(key) if key.is_a?(String)
    end
    
    size = options.delete(:size)
    options[:width], options[:height] = size.split("x") if size    
    width = options[:width]
    height = options[:height]
    has_layer = !options[:overlay].blank? || !options[:underlay].blank?
         
    crop = options.delete(:crop)
    angle = build_array(options.delete(:angle)).join(".")

    no_html_sizes = has_layer || !angle.blank? || crop.to_s == "fit" || crop.to_s == "limit" || crop.to_s == "lfill"
    options.delete(:width) if width && (width.to_f < 1 || no_html_sizes)
    options.delete(:height) if height && (height.to_f < 1 || no_html_sizes)

    width=height=nil if crop.nil? && !has_layer

    background = options.delete(:background)
    background = background.sub(/^#/, 'rgb:') if background
        
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
    
    params = {:w=>width, :h=>height, :t=>named_transformation, :c=>crop, :b=>background, :e=>effect, :a=>angle, :bo=>border, :fl=>flags}
    { :x=>:x, :y=>:y, :r=>:radius, :d=>:default_image, :g=>:gravity, :q=>:quality, :cs=>:color_space, :o=>:opacity,
      :p=>:prefix, :l=>:overlay, :u=>:underlay, :f=>:fetch_format, :dn=>:density, :pg=>:page, :dl=>:delay
    }.each do
      |param, option|
      params[param] = options.delete(option)
    end    

    transformation = params.reject{|k,v| v.blank?}.map{|k,v| [k.to_s, v]}.sort_by(&:first).map{|k,v| "#{k}_#{v}"}.join(",")
    raw_transformation = options.delete(:raw_transformation)
    transformation = [transformation, raw_transformation].reject(&:blank?).join(",")
    (base_transformations << transformation).reject(&:blank?).join("/")    
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

    resource_type = options.delete(:resource_type) || "image"
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
    
    original_source = source
    return original_source if source.blank?
    if defined?(CarrierWave::Uploader::Base) && source.is_a?(CarrierWave::Uploader::Base)
      source = format.blank? ? source.filename : source.full_public_id 
    end
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
    
    type ||= :upload

    if source.match(%r(^https?:/)i)
      source = smart_escape(source)
    elsif !format.blank? 
      source = "#{source}.#{format}"
    end

    if cloud_name.start_with?("/")
      prefix = "/res" + cloud_name
    else
      secure_distribution ||= Cloudinary::SHARED_CDN
            
      if secure
        prefix = "https://#{secure_distribution}"
      else
        subdomain = cdn_subdomain ? "a#{(Zlib::crc32(source) % 5) + 1}." : ""
        host = cname.blank? ? "#{private_cdn ? "#{cloud_name}-" : ""}res.cloudinary.com" : cname
        prefix = "http://#{subdomain}#{host}"
      end    
      prefix += "/#{cloud_name}" if !private_cdn || (secure && secure_distribution == Cloudinary::AKAMAI_SHARED_CDN)
    end
    
    if shorten && resource_type.to_s == "image" && type.to_s == "upload"
      resource_type = "iu"
      type = nil
    end
    version ||= 1 if source.include?("/") and !source.match(/^v[0-9]+/) and !source.match(/^https?:\//)
    source = prefix + "/" + [resource_type, 
     type, transformation, version ? "v#{version}" : nil,
     source].reject(&:blank?).join("/").gsub(%r(([^:])//), '\1/')
  end
  
  def self.cloudinary_api_url(action = 'upload', options = {})
    cloudinary = options[:upload_prefix] || Cloudinary.config.upload_prefix || "https://api.cloudinary.com"
    cloud_name = options[:cloud_name] || Cloudinary.config.cloud_name || raise(CloudinaryException, "Must supply cloud_name")
    resource_type = options[:resource_type] || "image"
    return [cloudinary, "v1_1", cloud_name, resource_type, action].join("/")
  end

  def self.private_download_url(public_id, format, options = {})
    api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
    cloudinary_params = {
      :timestamp=>Time.now.to_i, 
      :public_id=>public_id, 
      :format=>format, 
      :type=>options[:type],
      :attachment=>options[:attachment], 
      :expires_at=>options[:expires_at] && options[:expires_at].to_i
    }.reject{|k, v| v.blank?}
    cloudinary_params[:signature] = Cloudinary::Utils.api_sign_request(cloudinary_params, api_secret)
    cloudinary_params[:api_key] = api_key
    return Cloudinary::Utils.cloudinary_api_url("download", options) + "?" + cloudinary_params.to_query 
  end

  def self.zip_download_url(tag, options = {})
    api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
    cloudinary_params = {:timestamp=>Time.now.to_i, :tag=>tag, :transformation=>generate_transformation_string(options)}.reject{|k, v| v.blank?}
    cloudinary_params[:signature] = Cloudinary::Utils.api_sign_request(cloudinary_params, api_secret)
    cloudinary_params[:api_key] = api_key
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
    if options[:type].to_s == 'authenticated'
      result = signed_download_url(public_id, options)
    else
      result = unsigned_download_url(public_id, options)
    end
    return result
  end

  def self.asset_file_name(path)
    data = Rails.root.join(path).read(:mode=>"rb")
    ext = path.extname
    md5 = Digest::MD5.hexdigest(data)
    public_id = "#{path.basename(ext)}-#{md5}"
    "#{public_id}#{ext}"    
  end
  
  # Based on CGI::unescape. In addition does not escape / : 
  def self.smart_escape(string)
    string.gsub(/([^ a-zA-Z0-9_.-\/:]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end.tr(' ', '+')
  end
  
  def self.random_public_id
    sr = defined?(ActiveSupport::SecureRandom) ? ActiveSupport::SecureRandom : SecureRandom
    sr.base64(20).downcase.gsub(/[^a-z0-9]/, "").sub(/^[0-9]+/, '')[0,20]
  end

  def self.signed_preloaded_image(result)
    "#{result["resource_type"]}/upload/v#{result["version"]}/#{[result["public_id"], result["format"]].reject(&:blank?).join(".")}##{result["signature"]}"
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
end
