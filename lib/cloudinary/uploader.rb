# Copyright Cloudinary
require 'faraday'
require 'json'
require 'cloudinary/cache'

class Cloudinary::Uploader
  @adapter = nil
  def self.build_upload_params(options, as_bool = false)
    #symbolize keys
    options = options.clone
    options.keys.each { |key| options[key.to_sym] = options.delete(key) if key.is_a?(String) }

    params = {
      :access_control         => Cloudinary::Utils.json_array_param(options[:access_control]),
      :allowed_formats        => Cloudinary::Utils.build_array(options[:allowed_formats]).join(","),
      :auto_tagging           => options[:auto_tagging] && options[:auto_tagging].to_f,
      :context                => Cloudinary::Utils.encode_context(options[:context]),
      :custom_coordinates     => Cloudinary::Utils.encode_double_array(options[:custom_coordinates]),
      :eager                  => Cloudinary::Utils.build_eager(options[:eager]),
      :face_coordinates       => Cloudinary::Utils.encode_double_array(options[:face_coordinates]),
      :headers                => build_custom_headers(options[:headers]),
      :responsive_breakpoints => Cloudinary::Utils.generate_responsive_breakpoints_string(options[:responsive_breakpoints]),
      :tags                   => options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(","),
      :timestamp              => (options[:timestamp] || Time.now.to_i),
      :transformation         => Cloudinary::Utils.generate_transformation_string(options.clone),
      :metadata               => Cloudinary::Utils.encode_context(options[:metadata])
    }

    bool_params = [
      :async, :backup, :cinemagraph_analysis, :colors, :discard_original_filename, :eager_async, :exif, :faces,
      :image_metadata, :media_metadata, :invalidate, :overwrite, :phash, :quality_analysis, :return_delete_token,
      :visual_search, :unique_filename, :use_filename, :use_filename_as_display_name,
      :use_asset_folder_as_public_id_prefix, :unique_display_name, :accessibility_analysis
    ]

    string_params = [
      :access_mode, :asset_folder, :background_removal, :callback, :categorization, :detection, :display_name,
      :eager_notification_url, :eval, :on_success, :folder, :format, :filename_override, :moderation, :notification_url,
      :ocr, :proxy, :public_id, :public_id_prefix, :quality_override, :raw_convert, :similarity_search, :type,
      :upload_preset
    ]

    bool_params.each do |b|
      params[b] =  as_bool ? Cloudinary::Utils.as_bool(options[b]): Cloudinary::Utils.as_safe_bool(options[b])
    end

    string_params.each do |s|
      params[s] =  options[s]
    end

    params
  end

  def self.unsigned_upload(file, upload_preset, options={})
    upload(file, options.merge(:unsigned => true, :upload_preset => upload_preset))
  end

  def self.upload(file, options={})
    call_api("upload", options) do
      params = build_upload_params(options)
      params[:file] = Cloudinary::Utils.handle_file_param(file, options)
      [params, [:file]]
    end
  end

  # Upload large files. Note that public_id should include an extension for best results.
  def self.upload_large(file, public_id_or_options={}, old_options={})
    if public_id_or_options.is_a?(Hash)
      options   = public_id_or_options
      public_id = options[:public_id]
    else
      public_id = public_id_or_options
      options   = old_options
    end

    options.merge(:public_id => public_id)

    if Cloudinary::Utils.is_remote?(file)
      return upload(file, options)
    end

    if file.is_a?(Pathname) || !file.respond_to?(:read)
      filename = file
      file     = File.open(file, "rb")
    else
      filename = "cloudinaryfile"
    end

    chunk_size = options[:chunk_size] || 20_000_000

    if file.size < chunk_size
      return upload(file, options)
    end

    filename = options[:filename] if options[:filename]

    unique_upload_id = Cloudinary::Utils.random_public_id
    upload     = nil
    index      = 0

    until file.eof?
      buffer      = file.read(chunk_size)
      current_loc = index*chunk_size
      range       = "bytes #{current_loc}-#{current_loc+buffer.size - 1}/#{file.size}"
      upload      = upload_large_part(Cloudinary::Blob.new(buffer, :original_filename => filename),
                                      options.merge(:unique_upload_id => unique_upload_id, :content_range => range))
      index       += 1
    end
    upload
  end


  # Upload large  files. Note that public_id should include an extension for best results.
  def self.upload_large_part(file, options={})
    options[:resource_type] ||= :raw
    call_api("upload", options) do
      params = build_upload_params(options)
      params[:file] = Cloudinary::Utils.handle_file_param(file, options)
      [params, [:file]]
    end
  end

  def self.destroy(public_id, options={})
    call_api("destroy", options) do
      {
        :timestamp  => (options[:timestamp] || Time.now.to_i),
        :type       => options[:type],
        :public_id  => public_id,
        :invalidate => options[:invalidate],
      }
    end
  end

  def self.rename(from_public_id, to_public_id, options={})
    call_api("rename", options) do
      {
        :timestamp      => (options[:timestamp] || Time.now.to_i),
        :type           => options[:type],
        :overwrite      => Cloudinary::Utils.as_safe_bool(options[:overwrite]),
        :from_public_id => from_public_id,
        :to_public_id   => to_public_id,
        :to_type        => options[:to_type],
        :invalidate     => Cloudinary::Utils.as_safe_bool(options[:invalidate]),
        :context        => options[:context],
        :metadata       => options[:metadata]
      }
    end
  end

  def self.exists?(public_id, options={})
    cloudinary_url = Cloudinary::Utils.cloudinary_url(public_id, options)
    begin
      code = RestClient::Request.execute(:method => :head, :url => cloudinary_url, :timeout => 5).code
      code >= 200 && code < 300
    rescue RestClient::ResourceNotFound
      return false
    end

  end

  def self.explicit(public_id, options={})
    call_api("explicit", options) do
      params             = build_upload_params(options)
      params[:public_id] = public_id
      params
    end
  end

  # Creates a new archive in the server and returns information in JSON format
  def self.create_archive(options={}, target_format = nil)
    call_api("generate_archive", options) do
      params                 = Cloudinary::Utils.archive_params(options)
      params[:target_format] = target_format if target_format
      params
    end
  end

  # Creates a new zip archive in the server and returns information in JSON format
  def self.create_zip(options={})
    create_archive(options, "zip")
  end

  TEXT_PARAMS = [:public_id, :font_family, :font_size, :font_color, :text_align, :font_weight, :font_style, :background, :opacity, :text_decoration, :line_spacing]

  def self.text(text, options={})
    call_api("text", options) do
      params = { :timestamp => Time.now.to_i, :text => text }
      TEXT_PARAMS.each { |k| params[k] = options[k] unless options[k].nil? }
      params
    end
  end

  SLIDESHOW_PARAMS = [:notification_url, :public_id, :upload_preset]

  # Creates auto-generated video slideshow.
  #
  # @param [Hash] options Additional options.
  #
  # @return [Hash] Hash with meta information URLs of generated slideshow resources.
  def self.create_slideshow(options = {})
    options[:resource_type] ||= :video

    call_api("create_slideshow", options) do
      params = {
        :timestamp               => Time.now.to_i,
        :transformation          => Cloudinary::Utils.build_eager(options[:transformation]),
        :manifest_transformation => Cloudinary::Utils.build_eager(options[:manifest_transformation]),
        :manifest_json           => options[:manifest_json] && options[:manifest_json].to_json,
        :tags                    => options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(","),
        :overwrite               => Cloudinary::Utils.as_safe_bool(options[:overwrite])
      }
      SLIDESHOW_PARAMS.each { |k| params[k] = options[k] unless options[k].nil? }

      params
    end
  end

  # Generates sprites by merging multiple images into a single large image.
  #
  # @param [String|Hash] tag Treated as additional options when hash is passed, otherwise as a tag
  # @param [Hash] options Additional options. Should be omitted when +tag_or_options+ is a Hash
  #
  # @return [Hash] Hash with meta information URLs of generated sprite resources
  def self.generate_sprite(tag, options = {})
    version_store = options.delete(:version_store)

    result = call_api("sprite", options) do
      Cloudinary::Utils.build_multi_and_sprite_params(tag, options)
    end

    if version_store == :file && result && result["version"]
      if defined?(Rails) && defined?(Rails.root)
        FileUtils.mkdir_p("#{Rails.root}/tmp/cloudinary")
        File.open("#{Rails.root}/tmp/cloudinary/cloudinary_sprite_#{tag}.version", "w") { |file| file.print result["version"].to_s }
      end
    end
    return result
  end

  # Creates either a single animated image, video or a PDF.
  #
  # @param [String|Hash] tag Treated as additional options when hash is passed, otherwise as a tag
  # @param [Hash] options Additional options. Should be omitted when +tag_or_options+ is a Hash
  #
  # @return [Hash] Hash with meta information URLs of the generated file
  def self.multi(tag, options = {})
    call_api("multi", options) do
      Cloudinary::Utils.build_multi_and_sprite_params(tag, options)
    end
  end

  def self.explode(public_id, options={})
    call_api("explode", options) do
      {
        :timestamp        => (options[:timestamp] || Time.now.to_i),
        :public_id        => public_id,
        :type             => options[:type],
        :format           => options[:format],
        :notification_url => options[:notification_url],
        :transformation   => Cloudinary::Utils.generate_transformation_string(options.clone)
      }
    end
  end

  # options may include 'exclusive' (boolean) which causes clearing this tag from all other resources
  def self.add_tag(tag, public_ids = [], options = {})
    exclusive = options.delete(:exclusive)
    command   = exclusive ? "set_exclusive" : "add"
    return self.call_tags_api(tag, command, public_ids, options)
  end

  def self.remove_tag(tag, public_ids = [], options = {})
    return self.call_tags_api(tag, "remove", public_ids, options)
  end

  def self.replace_tag(tag, public_ids = [], options = {})
    return self.call_tags_api(tag, "replace", public_ids, options)
  end

  def self.remove_all_tags(public_ids = [], options = {})
    return self.call_tags_api(nil, "remove_all", public_ids, options)
  end

  # Populates metadata fields with the given values. Existing values will be overwritten.
  #
  # Any metadata-value pairs given are merged with any existing metadata-value pairs
  # (an empty value for an existing metadata field clears the value).
  #
  # @param [Hash] metadata    A list of custom metadata fields (by external_id) and the values to assign to each of them.
  # @param [Array] public_ids An array of Public IDs of assets uploaded to Cloudinary.
  # @param [Hash] options
  # @option options [String] :resource_type The type of file. Default: image. Valid values: image, raw, video.
  # @option options [String] :type          The storage type. Default: upload. Valid values: upload, private, authenticated
  # @return mixed a list of public IDs that were updated
  # @raise [Cloudinary::Api:Error]
  def self.update_metadata(metadata, public_ids, options = {})
    self.call_api("metadata", options) do
      {
        timestamp: (options[:timestamp] || Time.now.to_i),
        type: options[:type],
        public_ids: Cloudinary::Utils.build_array(public_ids),
        metadata: Cloudinary::Utils.encode_context(metadata),
        clear_invalid: Cloudinary::Utils.as_safe_bool(options[:clear_invalid])
      }
    end
  end

  private

  def self.call_tags_api(tag, command, public_ids = [], options = {})
    return call_api("tags", options) do
      {
        :timestamp  => (options[:timestamp] || Time.now.to_i),
        :tag        => tag,
        :public_ids => Cloudinary::Utils.build_array(public_ids),
        :command    => command,
        :type       => options[:type]
      }
    end
  end

  def self.add_context(context, public_ids = [], options = {})
    return self.call_context_api(context, "add", public_ids, options)
  end

  def self.remove_all_context(public_ids = [], options = {})
    return self.call_context_api(nil, "remove_all", public_ids, options)
  end

  private

  def self.call_context_api(context, command, public_ids = [], options = {})
    return call_api("context", options) do
      {
        :timestamp  => (options[:timestamp] || Time.now.to_i),
        :context    => Cloudinary::Utils.encode_context(context),
        :public_ids => Cloudinary::Utils.build_array(public_ids),
        :command    => command,
        :type       => options[:type]
      }
    end
  end

  def self.call_api(action, options)
    options      = options.clone
    return_error = options.delete(:return_error)
    use_cache = options[:use_cache] || Cloudinary.config.use_cache
    params, non_signable = yield
    non_signable         ||= []

    headers                       = { "User-Agent" => Cloudinary::USER_AGENT }
    headers['Content-Range']      = options[:content_range] if options[:content_range]
    headers['X-Unique-Upload-Id'] = options[:unique_upload_id] if options[:unique_upload_id]
    headers.merge!(options[:extra_headers]) if options[:extra_headers]

    oauth_token = options[:oauth_token] || Cloudinary.config.oauth_token

    if oauth_token
      headers["Authorization"] = "Bearer #{oauth_token}"
    elsif !options[:unsigned]
      api_key             = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
      api_secret          = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")
      signature_algorithm = options[:signature_algorithm]
      params[:signature]  = Cloudinary::Utils.api_sign_request(params.reject { |k, v| non_signable.include?(k) }, api_secret, signature_algorithm)
      params[:api_key]    = api_key
    end

    api_url   = Cloudinary::Utils.cloudinary_api_url(action, options)
    api_proxy = options[:api_proxy] || Cloudinary.config.api_proxy
    timeout   = options.fetch(:timeout) { Cloudinary.config.to_h.fetch(:timeout, 60) }

    conn =  Faraday.new(url: api_url) do |faraday|
      faraday.proxy = api_proxy if api_proxy
      faraday.request :multipart, **options
      faraday.request :url_encoded
      faraday.adapter @adapter || Faraday.default_adapter
    end

    response = conn.send(:post) do |req|
      req.headers = headers
      req.body = params.reject { |_, v| v.nil? || v=="" }
      req.options.timeout = timeout if timeout
    end

    raise CloudinaryException, "Server returned unexpected status code - #{response.status} - #{response.body}" unless [200, 400, 401, 403, 404, 500].include?(response.status)
    begin
      result = Cloudinary::Utils.json_decode(response.body)
    rescue => e
      # Error is parsing json
      raise CloudinaryException, "Error parsing server response (#{response.status}) - #{response.body}. Got - #{e}"
    end
    if result["error"]
      if return_error
        result["error"]["http_code"] = response.status
      else
        raise CloudinaryException, result["error"]["message"]
      end
    end

    if use_cache && !result.nil?
      cache_results(result)
    end
    result
  end

  def self.build_custom_headers(headers)
    Array(headers).map { |*a| a.join(": ") }.join("\n")
  end

  def self.cache_results(result)
      if result["responsive_breakpoints"]
        result["responsive_breakpoints"].each do |bp|
          Cloudinary::Cache.set(
            result["public_id"],
            {type: result["type"], resource_type: result["resource_type"], raw_transformation: bp["transformation"]},
            bp["breakpoints"].map{|o| o['width']}
          )
          end
      end

      end
end
