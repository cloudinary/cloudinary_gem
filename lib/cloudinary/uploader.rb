# Copyright Cloudinary
require 'rest_client'
require 'json'

class Cloudinary::Uploader
  
  def self.build_eager(eager)
    return nil if eager.nil?
    Cloudinary::Utils.build_array(eager).map do
      |transformation, format|
      transformation = transformation.clone
      format = transformation.delete(:format) || format
      [Cloudinary::Utils.generate_transformation_string(transformation), format].compact.join("/")
    end.join("|")
  end
  
  def self.build_upload_params(options)
    #symbolize keys
    options = options.clone
    options.keys.each{|key| options[key.to_sym] = options.delete(key) if key.is_a?(String)}
    
    params = {:timestamp=>(options[:timestamp] || Time.now.to_i),
              :transformation => Cloudinary::Utils.generate_transformation_string(options.clone),
              :public_id=>options[:public_id],
              :callback=>options[:callback],
              :format=>options[:format],
              :type=>options[:type],
              :backup=>Cloudinary::Utils.as_safe_bool(options[:backup]),
              :faces=>Cloudinary::Utils.as_safe_bool(options[:faces]),
              :exif=>Cloudinary::Utils.as_safe_bool(options[:exif]),
              :colors=>Cloudinary::Utils.as_safe_bool(options[:colors]),
              :image_metadata=>Cloudinary::Utils.as_safe_bool(options[:image_metadata]),
              :invalidate=>Cloudinary::Utils.as_safe_bool(options[:invalidate]),
              :eager=>build_eager(options[:eager]),
              :headers=>build_custom_headers(options[:headers]),
              :use_filename=>Cloudinary::Utils.as_safe_bool(options[:use_filename]),
              :unique_filename=>Cloudinary::Utils.as_safe_bool(options[:unique_filename]),
              :overwrite=>Cloudinary::Utils.as_safe_bool(options[:overwrite]),
              :discard_original_filename=>Cloudinary::Utils.as_safe_bool(options[:discard_original_filename]),
              :notification_url=>options[:notification_url],
              :eager_notification_url=>options[:eager_notification_url],
              :eager_async=>Cloudinary::Utils.as_safe_bool(options[:eager_async]),
              :proxy=>options[:proxy],
              :folder=>options[:folder],
              :allowed_formats =>  Cloudinary::Utils.build_array(options[:allowed_formats]).join(","),
              :tags=>options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(","),
              :context => Cloudinary::Utils.encode_hash(options[:context]),
              :face_coordinates => Cloudinary::Utils.encode_double_array(options[:face_coordinates]),
              :custom_coordinates => Cloudinary::Utils.encode_double_array(options[:custom_coordinates]),
              :moderation => options[:moderation],
              :raw_convert => options[:raw_convert],
              :ocr => options[:ocr],
              :categorization => options[:categorization],
              :detection => options[:detection],
              :similarity_search => options[:similarity_search],
              :background_removal => options[:background_removal],
              :auto_tagging => options[:auto_tagging] && options[:auto_tagging].to_f,
              :upload_preset => options[:upload_preset],
              :phash => Cloudinary::Utils.as_safe_bool(options[:phash]),
              :return_delete_token => Cloudinary::Utils.as_safe_bool(options[:return_delete_token]),
            }
    params    
  end
  
  def self.unsigned_upload(file, upload_preset, options={})
    upload(file, options.merge(:unsigned => true, :upload_preset => upload_preset))
  end
   
  def self.upload(file, options={})
    call_api("upload", options) do    
      params = build_upload_params(options)
      if file.is_a?(Pathname)
        params[:file] = File.open(file, "rb")
      elsif file.respond_to?(:read) || file =~ /^ftp:|^https?:|^s3:|^data:[^;]*;base64,([a-zA-Z0-9\/+\n=]+)$/
        params[:file] = file
      else 
        params[:file] = File.open(file, "rb")
      end
      [params, [:file]]
    end              
  end

  # Upload large files. Note that public_id should include an extension for best results.
  def self.upload_large(file, public_id_or_options={}, old_options={})
    if public_id_or_options.is_a?(Hash)
      options = public_id_or_options
      public_id = options[:public_id]
    else
      public_id = public_id_or_options
      options = old_options
    end 
    if file.is_a?(Pathname) || !file.respond_to?(:read)
      filename = file
      file = File.open(file, "rb")
    else
      filename = "cloudinaryfile"
    end
    upload = upload_id = nil
    index = 0
    chunk_size = options[:chunk_size] || 20_000_000
    while !file.eof?
      buffer = file.read(chunk_size)
      current_loc = index*chunk_size
      range = "bytes #{current_loc}-#{current_loc+buffer.size - 1}/#{file.size}"
      upload = upload_large_part(Cloudinary::Blob.new(buffer, :original_filename=>filename), options.merge(:public_id=>public_id, :content_range=>range))
      public_id = upload["public_id"]      
      index += 1
    end
    upload
  end
    

  # Upload large  files. Note that public_id should include an extension for best results.
  def self.upload_large_part(file, options={})
    options[:resource_type] ||= :raw
    call_api("upload", options) do    
      params = build_upload_params(options)
      if file.is_a?(Pathname) || !file.respond_to?(:read)
        params[:file] = File.open(file, "rb")
      else
        params[:file] = file
      end
      [params, [:file]]
    end              
  end

  def self.destroy(public_id, options={})
    call_api("destroy", options) do    
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :type=>options[:type],
        :public_id=> public_id,
        :invalidate=>options[:invalidate],
      }
    end              
  end

  def self.rename(from_public_id, to_public_id, options={})
    call_api("rename", options) do    
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :type=>options[:type],
        :overwrite=>options[:overwrite],
        :from_public_id=>from_public_id,
        :to_public_id=>to_public_id,
      }
    end              
  end

  def self.exists?(public_id, options={})
    cloudinary_url = Cloudinary::Utils.cloudinary_url(public_id, options)
    begin
      RestClient::Request.execute(:method => :head, :url => cloudinary_url, :timeout=>5).code.to_s =~ /2\d{2}/
    rescue RestClient::ResourceNotFound => e
      return false
    end
    
  end

  def self.explicit(public_id, options={})
    call_api("explicit", options) do    
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :type=>options[:type],
        :public_id=> public_id,
        :callback=> options[:callback],
        :eager=>build_eager(options[:eager]),
        :eager_notification_url=>options[:eager_notification_url],
        :eager_async=>Cloudinary::Utils.as_safe_bool(options[:eager_async]),
        :headers=>build_custom_headers(options[:headers]),
        :tags=>options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(","),
        :face_coordinates => options[:face_coordinates] && Cloudinary::Utils.encode_double_array(options[:face_coordinates])  
      }
    end              
  end
    
  TEXT_PARAMS = [:public_id, :font_family, :font_size, :font_color, :text_align, :font_weight, :font_style, :background, :opacity, :text_decoration, :line_spacing]  
  def self.text(text, options={})
    call_api("text", options) do
      params = {:timestamp => Time.now.to_i, :text=>text}
      TEXT_PARAMS.each{|k| params[k] = options[k] if !options[k].nil?}
      params
    end
  end  
    
  def self.generate_sprite(tag, options={})
    version_store = options.delete(:version_store)
    
    result = call_api("sprite", options) do
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :tag=>tag,
        :async=>options[:async],
        :notification_url=>options[:notification_url],
        :transformation => Cloudinary::Utils.generate_transformation_string(options.merge(:fetch_format=>options[:format]))        
      }    
    end
    
    if version_store == :file && result && result["version"]
      if defined?(Rails) && defined?(Rails.root)
        FileUtils.mkdir_p("#{Rails.root}/tmp/cloudinary")
        File.open("#{Rails.root}/tmp/cloudinary/cloudinary_sprite_#{tag}.version", "w"){|file| file.print result["version"].to_s}                      
      end  
    end      
    return result
  end

  def self.multi(tag, options={})
    call_api("multi", options) do
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :tag=>tag,
        :format=>options[:format],
        :async=>options[:async],
        :notification_url=>options[:notification_url],
        :transformation => Cloudinary::Utils.generate_transformation_string(options.clone)        
      }    
    end
  end
  
  def self.explode(public_id, options={})    
    call_api("explode", options) do
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :public_id=>public_id,
        :type=>options[:type],
        :format=>options[:format],
        :notification_url=>options[:notification_url],
        :transformation => Cloudinary::Utils.generate_transformation_string(options.clone)        
      }    
    end
  end
    
  # options may include 'exclusive' (boolean) which causes clearing this tag from all other resources 
  def self.add_tag(tag, public_ids = [], options = {})
    exclusive = options.delete(:exclusive)
    command = exclusive ? "set_exclusive" : "add"
    return self.call_tags_api(tag, command, public_ids, options)    
  end

  def self.remove_tag(tag, public_ids = [], options = {})
    return self.call_tags_api(tag, "remove", public_ids, options)    
  end

  def self.replace_tag(tag, public_ids = [], options = {})
    return self.call_tags_api(tag, "replace", public_ids, options)    
  end
  
  private
  
  def self.call_tags_api(tag, command, public_ids = [], options = {})
    return call_api("tags", options) do
      {
        :timestamp=>(options[:timestamp] || Time.now.to_i),
        :tag=>tag,
        :public_ids => Cloudinary::Utils.build_array(public_ids),
        :command => command,
        :type => options[:type]
      }    
    end    
  end
     
  def self.call_api(action, options)
    options = options.clone
    return_error = options.delete(:return_error)

    params, non_signable = yield
    non_signable ||= []
    
    unless options[:unsigned]
      api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
      api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
      params[:signature] = Cloudinary::Utils.api_sign_request(params.reject{|k,v| non_signable.include?(k)}, api_secret)
      params[:api_key] = api_key
    end
    timeout = options[:timeout] || Cloudinary.config.timeout || 60

    result = nil
    
    api_url = Cloudinary::Utils.cloudinary_api_url(action, options)
    headers = {"User-Agent" => Cloudinary::USER_AGENT}
    headers['Content-Range'] = options[:content_range] if options[:content_range]
    RestClient::Request.execute(:method => :post, :url => api_url, :payload => params.reject{|k, v| v.nil? || v==""}, :timeout=> timeout, :headers => headers) do
      |response, request, tmpresult|
      raise CloudinaryException, "Server returned unexpected status code - #{response.code} - #{response.body}" if ![200,400,401,403,404,500].include?(response.code)
      begin
        result = Cloudinary::Utils.json_decode(response.body)
      rescue => e
        # Error is parsing json
        raise CloudinaryException, "Error parsing server response (#{response.code}) - #{response.body}. Got - #{e}"
      end
      if result["error"]
        if return_error
          result["error"]["http_code"] = response.code
        else
          raise CloudinaryException, result["error"]["message"]
        end
      end        
    end
    
    result    
  end
  
  def self.build_custom_headers(headers)
    Array(headers).map{|*a| a.join(": ")}.join("\n")
  end
end
