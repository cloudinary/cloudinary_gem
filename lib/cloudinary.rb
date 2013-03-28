# Copyright Cloudinary
require "ostruct"
require "pathname"
require "yaml"
require "uri"
require "erb"
require "cloudinary/version"
require "cloudinary/exceptions"
require "cloudinary/missing"
require "cloudinary/helper" if defined?(::ActionView::Base)
require "cloudinary/controller" if defined?(::ActionController::Base)
require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)
require "cloudinary/engine" if defined?(Rails) && defined?(Rails::Engine)

module Cloudinary
  autoload :Utils, 'cloudinary/utils'
  autoload :Uploader, 'cloudinary/uploader'
  autoload :Api, "cloudinary/api"
  autoload :Downloader, "cloudinary/downloader"
  autoload :Blob, "cloudinary/blob"
  autoload :PreloadedFile, "cloudinary/preloaded_file"
  autoload :Static, "cloudinary/static"  
  autoload :CarrierWave, "cloudinary/carrier_wave"  
  
  CF_SHARED_CDN = "d3jpl91pxevbkh.cloudfront.net"
  AKAMAI_SHARED_CDN = "cloudinary-a.akamaihd.net"
  SHARED_CDN = AKAMAI_SHARED_CDN  
    
  FORMAT_ALIASES = {
    "jpeg" => "jpg",
    "jpe" => "jpg",
    "tif" => "tiff",
    "ps" => "eps",
    "ept" => "eps"
  }
  
  @@config = nil
  
  def self.config(new_config=nil)
    first_time = @@config.nil?
    @@config ||= OpenStruct.new((YAML.load(ERB.new(IO.read(config_dir.join("cloudinary.yml"))).result)[config_env] rescue {}))
        
    # Heroku support
    if first_time && ENV["CLOUDINARY_CLOUD_NAME"]
      set_config(
        "cloud_name" => ENV["CLOUDINARY_CLOUD_NAME"],
        "api_key" => ENV["CLOUDINARY_API_KEY"],
        "api_secret" => ENV["CLOUDINARY_API_SECRET"],
        "secure_distribution" => ENV["CLOUDINARY_SECURE_DISTRIBUTION"],
        "private_cdn" => ENV["CLOUDINARY_PRIVATE_CDN"].to_s == 'true'
      )
    elsif first_time && ENV["CLOUDINARY_URL"]
      config_from_url(ENV["CLOUDINARY_URL"])
    end

    set_config(new_config) if new_config
    yield(@@config) if block_given?

    @@config    
  end
  
  def self.config_from_url(url)
    @@config ||= OpenStruct.new
    uri = URI.parse(url)
    set_config(
      "cloud_name" => uri.host,
      "api_key" => uri.user,
      "api_secret" => uri.password,
      "private_cdn" => !uri.path.blank?,
      "secure_distribution" => uri.path[1..-1]
    )
    uri.query.to_s.split("&").each do
      |param|
      key, value = param.split("=")
      set_config(key=>URI.decode(value))
    end    
  end
  
  private
  
  def self.config_env
    return ENV["CLOUDINARY_ENV"] if ENV["CLOUDINARY_ENV"]
    return Rails.env if defined?(Rails)
    nil
  end
  
  def self.config_dir
    return Pathname.new(ENV["CLOUDINARY_CONFIG_DIR"]) if ENV["CLOUDINARY_CONFIG_DIR"] 
    return Rails.root.join("config") if defined?(Rails)
    Pathname.new("config")
  end
  
  def self.set_config(new_config)
    new_config.each{|k,v| @@config.send(:"#{k}=", v) if !v.nil?}
  end
end
