require 'digest/md5'
module CloudinaryHelper
  include ActionView::Helpers::AssetTagHelper  
  alias :original_image_tag :image_tag
  alias :original_image_path :image_path
      
  # Examples
  # cl_image_tag "israel.png", :width=>100, :height=>100, :alt=>"hello" # W/H are not sent to cloudinary
  # cl_image_tag "israel.png", :width=>100, :height=>100, :alt=>"hello", :crop=>:fit # W/H are sent to cloudinary
  def cl_image_tag(source, options = {})
    options = options.clone
    source = cloudinary_url_internal(source, options)
    options[:width] = options.delete(:html_width) if options.include?(:html_width)
    options[:height] = options.delete(:html_height) if options.include?(:html_height)
    options[:size] = options.delete(:html_size) if options.include?(:html_size)
    options[:border] = options.delete(:html_border) if options.include?(:html_border)

    original_image_tag(source, options)
  end

  def cl_image_path(source, options = {})
    options = options.clone
    url = cloudinary_url_internal(source, options)
    original_image_path(url)    
  end
    
  def image_tag(*args)
    if Cloudinary.config.enhance_image_tag
      source, options = args
      cl_image_tag(source, {:type=>:asset}.merge(options || {}))
    else
      original_image_tag(*args)
    end
  end

  def image_path(*args)
    if Cloudinary.config.enhance_image_tag
      source, options = args
      cl_image_path(source, {:type=>:asset}.merge(options || {}))
    else
      original_image_path(*args)
    end
  end

  def fetch_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:fetch}.merge(options))
  end
  
  def facebook_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:facebook}.merge(options))
  end
  
  def facebook_profile_image_path(profile, options = {})    
    cl_image_path(profile, {:type=>:facebook}.merge(options))
  end

  def gravatar_profile_image_tag(email, options = {})    
    cl_image_tag(Digest::MD5.hexdigest(email.strip.downcase), {:type=>:gravatar, :format=>:jpg}.merge(options))
  end
  
  def gravatar_profile_image_path(email, options = {})    
    cl_image_path(Digest::MD5.hexdigest(email.strip.downcase), {:type=>:gravatar, :format=>:jpg}.merge(options))
  end

  def twitter_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:twitter}.merge(options))
  end
  
  def twitter_profile_image_path(profile, options = {})    
    cl_image_path(profile, {:type=>:twitter}.merge(options))
  end

  def twitter_name_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:twitter_name}.merge(options))
  end
  
  def twitter_name_profile_image_path(profile, options = {})    
    cl_image_path(profile, {:type=>:twitter_name}.merge(options))
  end
  
  def gplus_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:gplus}.merge(options))
  end
  
  def gplus_profile_image_path(profile, options = {})    
    cl_image_path(profile, {:type=>:gplus}.merge(options))
  end

  def cl_sprite_url(source, options = {})
    options = options.clone
    
    version_store = options.delete(:version_store)
    if options[:version].blank? && (version_store == :file) && defined?(Rails) && defined?(Rails.root)
      file_name = "#{Rails.root}/tmp/cloudinary/cloudinary_sprite_#{source.sub(/\..*/, '')}.version"
      if File.exists?(file_name)
        options[:version] = File.read(file_name).chomp        
      end
    end  
    
    options[:format] = "css" unless source.ends_with?(".css")
    cloudinary_url_internal(source, options.merge(:type=>:sprite))
  end

  def cl_sprite_tag(source, options = {})
    stylesheet_link_tag(cl_sprite_url(source, options))
  end

  # cl_form_tag was originally contributed by Milovan Zogovic
  def cl_form_tag(callback_url, options={}, &block)
    form_options = options.delete(:form) || {}
    form_options[:method] = :post
    form_options[:multipart] = true
     
    params = Cloudinary::Uploader.build_upload_params(options.merge(:callback=>callback_url))  
    params[:signature] = Cloudinary::Utils.api_sign_request(params, Cloudinary.config.api_secret)  
    params[:api_key] = Cloudinary.config.api_key
  
    api_url = Cloudinary::Utils.cloudinary_api_url("upload", 
                {:resource_type => options.delete(:resource_type), :upload_prefix => options.delete(:upload_prefix)})

    form_tag(api_url, form_options) do
      content = []
  
      params.each do |name, value|
        content << hidden_field_tag(name, value, :id => nil) if value.present?
      end
  
      content << capture(&block)
  
      content.join("\n").html_safe
    end
  end

  CLOUDINARY_JS_CONFIG_PARAMS = [:api_key, :cloud_name, :private_cdn, :secure_distribution, :cdn_subdomain]
  def cloudinary_js_config
    params = {}
    CLOUDINARY_JS_CONFIG_PARAMS.each do
      |param| 
      value = Cloudinary.config.send(param)
      params[param] = value if !value.nil?
    end    
    content_tag("script", "$.cloudinary.config(#{params.to_json});".html_safe, :type=>"text/javascript")      
  end

  def cloudinary_url(source, options = {})
    cloudinary_url_internal(source, options.clone)
  end
  
  def cl_image_upload(object_name, method, options={})
    cl_image_upload_tag("#{object_name}[#{method}]", options)
  end
  
  def cl_image_upload_tag(field, options={})
    html_options = options.delete(:html) || {}
    cloudinary_upload_url = Cloudinary::Utils.cloudinary_api_url("upload", {:resource_type=>:auto}.merge(options))
    
    api_key = options[:api_key] || Cloudinary.config.api_key || raise(CloudinaryException, "Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise(CloudinaryException, "Must supply api_secret")

    cloudinary_params = Cloudinary::Uploader.build_upload_params(options)
    cloudinary_params[:callback] = build_callback_url(options)
    cloudinary_params[:signature] = Cloudinary::Utils.api_sign_request(cloudinary_params, api_secret)
    cloudinary_params[:api_key] = api_key

    tag_options = html_options.merge(:type=>"file", :name=>"file", 
      :"data-url"=>cloudinary_upload_url,
      :"data-form-data"=>cloudinary_params.reject{|k, v| v.blank?}.to_json,
      :"data-cloudinary-field"=>field,
      :"class" => [html_options[:class], "cloudinary-fileupload"].flatten.compact 
    ).reject{|k,v| v.blank?}
    content_tag("input", nil, tag_options)
  end
  
  def cl_private_download_url(public_id, format, options = {})
    Cloudinary::Utils.private_download_url(public_id, format, options)
  end

  def cl_zip_download_url(tag, options = {})
    Cloudinary::Utils.zip_download_url(tag, options)
  end

  def cl_signed_download_url(public_id, options = {})
    Cloudinary::Utils.signed_download_url(public_id, options)
  end
  
  def self.included(base)
    ActionView::Helpers::FormBuilder.send(:include, Cloudinary::FormBuilder)
  end
  
  private
  def cloudinary_url_internal(source, options = {})
    options[:ssl_detected] = request.ssl? if defined?(request) && request && request.respond_to?(:ssl?)
    if defined?(CarrierWave::Uploader::Base) && source.is_a?(CarrierWave::Uploader::Base)      
      if source.version_name.present?
        options[:transformation] = Cloudinary::Utils.build_array(source.transformation) + Cloudinary::Utils.build_array(options[:transformation]) 
      end         
      options.reverse_merge!(      
        :resource_type => Cloudinary::Utils.resource_type_for_format(source.filename || source.format),
        :type => source.storage_type,
        :format => source.format)
      source = source.full_public_id      
    end
    Cloudinary::Utils.cloudinary_url(source, options)
  end  

  def build_callback_url(options)
    callback_path = options.delete(:callback_cors) || Cloudinary.config.callback_cors || "/cloudinary_cors.html"
    if !callback_path.match(/^https?:\/\//)
      callback_url = request.scheme + "://"
      callback_url << request.host
      if request.scheme == "https" && request.port != 443 ||
        request.scheme == "http" && request.port != 80
        callback_url << ":#{request.port}"
      end
      callback_url << callback_path
    end
    callback_url
  end  
end

module Cloudinary::FormBuilder
  def cl_image_upload(method, options={})
    @template.cl_image_upload(@object_name, method, objectify_options(options))
  end
end

if defined? ActionView::Helpers::AssetUrlHelper
  module ActionView::Helpers::AssetUrlHelper
    alias :original_path_to_asset :path_to_asset
  
    def path_to_asset(source, options={})
      options ||= {}
      if Cloudinary.config.enhance_image_tag && options[:type] == :image
        source = Cloudinary::Utils.cloudinary_url(source, options.merge(:type=>:asset))
      end
      original_path_to_asset(source, options)
    end    
  end
end

ActionView::Base.send :include, CloudinaryHelper

begin
  require 'sass-rails'
  if defined?(Sass::Rails::Resolver)
    class Sass::Rails::Resolver
      alias :original_image_path :image_path
      def image_path(img)
        if Cloudinary.config.enhance_image_tag
          original_image_path(Cloudinary::Utils.cloudinary_url(img, :type=>:asset))
        else
          original_image_path(img)
        end      
      end      
    end
  end  
rescue LoadError
  # no sass rails support. Ignore.
end

begin
  require 'sass'
  require 'sass/script/functions'
  module Sass::Script::Functions
    def cloudinary_url(public_id, sass_options={})
      options = {}
      sass_options.each{|k, v| options[k.to_sym] = v.value}
      url = Cloudinary::Utils.cloudinary_url(public_id.value, {:type=>:asset}.merge(options))
      Sass::Script::String.new("url(#{url})")      
    end
    declare :cloudinary_url, [:string], :var_kwargs => true
  end
rescue LoadError
  # no sass support. Ignore.
end
  
