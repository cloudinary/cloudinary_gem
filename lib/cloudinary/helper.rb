# Copyright Cloudinary

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

  def cloudinary_url(source, options = {})
    options[:secure] = request.ssl? if !options.include?(:secure) && defined?(request) && request && request.respond_to?(:ssl?)
    Cloudinary::Utils.cloudinary_url(source, options)
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

