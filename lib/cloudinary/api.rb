class Cloudinary::Api
  class Error < CloudinaryException; end
  class NotFound < Error; end
  class NotAllowed < Error; end
  class AlreadyExists < Error; end
  class RateLimited < Error; end
  class BadRequest < Error; end
  class GeneralError < Error; end
  class AuthorizationRequired < Error; end 
  class Response < Hash
    attr_reader :rate_limit_reset_at, :rate_limit_remaining, :rate_limit_allowed
    def initialize(response)
      self.update(Cloudinary::Api.send(:parse_json_response, response))
      @rate_limit_allowed = response.headers[:x_featureratelimit_limit].to_i
      @rate_limit_reset_at = Time.parse(response.headers[:x_featureratelimit_reset])
      @rate_limit_remaining = response.headers[:x_featureratelimit_remaining].to_i     
    end
  end
  
  
  def self.resource_types(options={})
    call_api(:get, "resources", {}, options)
  end

  def self.resources(options={})
    resource_type = options[:resource_type] || "image"
    type = options[:type]
    uri = "resources/#{resource_type}"
    uri += "/#{type}" if !type.blank?
    call_api(:get, uri, only(options, :next_cursor, :max_results, :prefix), options)    
  end
  
  def self.resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri = "resources/#{resource_type}/tags/#{tag}"
    call_api(:get, uri, only(options, :next_cursor, :max_results), options)    
  end
  
  def self.resource(public_id, options={})
    resource_type = options[:resource_type] || "image"
    type = options[:type] || "upload"
    uri = "resources/#{resource_type}/#{type}/#{public_id}"
    call_api(:get, uri, only(options, :colors, :exif, :faces, :pages, :max_results), options)      
  end
  
  def self.delete_resources(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type = options[:type] || "upload"    
    uri = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, {:public_ids=>public_ids}.merge(only(options, :keep_original)), options)      
  end

  def self.delete_resources_by_prefix(prefix, options={})
    resource_type = options[:resource_type] || "image"
    type = options[:type] || "upload"    
    uri = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, {:prefix=>prefix}.merge(only(options, :keep_original)), options)      
  end
  
  def self.delete_resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri = "resources/#{resource_type}/tags/#{tag}"
    call_api(:delete, uri, only(options, :keep_original), options)    
  end
  
  def self.delete_derived_resources(derived_resource_ids, options={})
    uri = "derived_resources"
    call_api(:delete, uri, {:derived_resource_ids=>derived_resource_ids}, options)      
  end

  def self.tags(options={})
    resource_type = options[:resource_type] || "image"
    uri = "tags/#{resource_type}"
    call_api(:get, uri, only(options, :next_cursor, :max_results, :prefix), options)    
  end
  
  def self.transformations(options={})
    call_api(:get, "transformations", only(options, :next_cursor, :max_results), options)    
  end

  def self.transformation(transformation, options={})
    call_api(:get, "transformations/#{transformation_string(transformation)}", only(options, :max_results), options)    
  end
  
  def self.delete_transformation(transformation, options={})
    call_api(:delete, "transformations/#{transformation_string(transformation)}", {}, options)    
  end
  
  # updates - currently only supported update is the "allowed_for_strict" boolean flag
  def self.update_transformation(transformation, updates, options={})
    call_api(:put, "transformations/#{transformation_string(transformation)}", only(updates, :allowed_for_strict), options)
  end
  
  def self.create_transformation(name, definition, options={})
    call_api(:post, "transformations/#{name}", {:transformation=>transformation_string(definition)}, options)
  end
  
  protected
  
  def self.call_api(method, uri, params, options)
    cloudinary = options[:upload_prefix] || Cloudinary.config.upload_prefix || "https://api.cloudinary.com"
    cloud_name = options[:cloud_name] || Cloudinary.config.cloud_name || raise("Must supply cloud_name")
    api_key = options[:api_key] || Cloudinary.config.api_key || raise("Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise("Must supply api_secret")
    api_url = [cloudinary, "v1_1", cloud_name, uri].join("/")
    # Add authentication
    api_url.sub!(%r(^(https?://)), "\\1#{api_key}:#{api_secret}@")
    
    RestClient::Request.execute(:method => method, :url => api_url, :payload => params.reject{|k, v| v.nil? || v==""}, :timeout=>60) do
      |response, request, tmpresult|
      return Response.new(response) if response.code == 200
      exception_class = case response.code
        when 400 then BadRequest
        when 401 then AuthorizationRequired
        when 403 then NotAllowed
        when 404 then NotFound
        when 409 then AlreadyExists
        when 420 then RateLimited
        when 500 then GeneralError
        else raise GeneralError.new("Server returned unexpected status code - #{response.code} - #{response.body}")   
      end
      json = parse_json_response(response)
      raise exception_class.new(json["error"]["message"])
    end    
  end
  
  def self.parse_json_response(response)
    return Cloudinary::Utils.json_decode(response.body)
  rescue => e
    # Error is parsing json
    raise GeneralError.new("Error parsing server response (#{response.code}) - #{response.body}. Got - #{e}")
  end
  
  def self.only(hash, *keys)
    result = {}
    keys.each do
      |key| 
      result[key] = hash[key] if hash.include?(key)
      result[key] = hash[key.to_s] if hash.include?(key.to_s)
    end
    result
  end  
  
  def self.transformation_string(transformation)
    transformation = transformation.is_a?(String) ? transformation : Cloudinary::Utils.generate_transformation_string(transformation.clone)
  end
end
