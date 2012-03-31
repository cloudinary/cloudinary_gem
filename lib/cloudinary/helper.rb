# Copyright Cloudinary

module CloudinaryHelper  
  # Examples
  # cl_image_tag "israel.png", :width=>100, :height=>100, :alt=>"hello" # W/H are not sent to cloudinary
  # cl_image_tag "israel.png", :width=>100, :height=>100, :alt=>"hello", :crop=>:fit # W/H are sent to cloudinary
  def cl_image_tag(source, options = {})
    options = options.clone
    source = cloudinary_url(source, options)
    options[:width] = options.delete(:html_width) if options.include?(:html_width)
    options[:height] = options.delete(:html_height) if options.include?(:html_height)
    options[:size] = options.delete(:html_size) if options.include?(:html_size)

    image_tag(source, options)
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
