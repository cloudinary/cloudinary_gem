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
    source = cloudinary_url(source, options)
    options[:width] = options.delete(:html_width) if options.include?(:html_width)
    options[:height] = options.delete(:html_height) if options.include?(:html_height)
    options[:size] = options.delete(:html_size) if options.include?(:html_size)

    original_image_tag(source, options)
  end

  def cl_image_path(source, options = {})
    options = options.clone
    url = cloudinary_url(source, options)
    original_image_path(url, options)    
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

  def gravatar_profile_image_tag(email, options = {})    
    cl_image_tag(Digest::MD5.hexdigest(email.strip.downcase), {:type=>:gravatar, :format=>:jpg}.merge(options))
  end

  def twitter_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:twitter}.merge(options))
  end

  def twitter_name_profile_image_tag(profile, options = {})    
    cl_image_tag(profile, {:type=>:twitter_name}.merge(options))
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
    cloudinary_url(source, options.merge(:type=>:sprite))
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
    CLOUDINARY_JS_CONFIG_PARAMS.each{|param| params[param] = Cloudinary.config.send(param)}    
    content_tag("script", "$.cloudinary.config(#{params.to_json});".html_safe, :type=>"text/javascript")      
  end

  def cloudinary_url(source, options = {})
    options[:secure] = request.ssl? if !options.include?(:secure) && defined?(request) && request && request.respond_to?(:ssl?)
    Cloudinary::Utils.cloudinary_url(source, options)
  end  

  def cl_image_upload(object_name, method, options={})
    cl_image_upload_tag("#{object_name}[#{method}]", options)
  end
  
  def cl_image_upload_tag(field, options={})
    html_options = options.delete(:html) || {}
    cloudinary_upload_url = Cloudinary::Utils.cloudinary_api_url("upload", {:resource_type=>:auto}.merge(options))
    
    api_key = options[:api_key] || Cloudinary.config.api_key || raise("Must supply api_key")
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise("Must supply api_secret")

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
  
  def self.included(base)
    ActionView::Helpers::FormBuilder.send(:include, Cloudinary::FormBuilder)
  end
  
  private
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

ActionView::Base.send :include, CloudinaryHelper

if defined?(Sass::Rails)
  class Sass::Rails::Resolver
    alias :original_image_path :image_path
    def image_path(img)
      if Cloudinary.config.enhance_image_tag
        Cloudinary::Utils.cloudinary_url(img, :type=>:asset)
      else
        original_image_path(img)
      end      
    end      
  end  
end

