# Copyright Cloudinary
require "ostruct"
require "pathname"
require "yaml"
require "cloudinary/version"
require "cloudinary/utils"
require "cloudinary/uploader"
require "cloudinary/downloader"
require "cloudinary/blob" 
require "cloudinary/static"
require "cloudinary/missing"
require "cloudinary/carrier_wave" if defined?(::CarrierWave)
require "cloudinary/helper" if defined?(::ActionView::Base)
require "cloudinary/controller" if defined?(::ActionController::Base)
require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)

module Cloudinary  
  @@config = nil
  
  def self.config(new_config=nil)
    first_time = @@config.nil?
    @@config ||= OpenStruct.new((YAML.load_file(config_dir.join("cloudinary.yml"))[config_env] rescue {}))
        
    # Heroku support
    if first_time && ENV["CLOUDINARY_CLOUD_NAME"]
      set_config(
        "cloud_name" => ENV["CLOUDINARY_CLOUD_NAME"],
        "api_key" => ENV["CLOUDINARY_API_KEY"],
        "api_secret" => ENV["CLOUDINARY_API_SECRET"],
        "secure_distribution" => ENV["CLOUDINARY_SECURE_DISTRIBUTION"],
        "private_cdn" => ENV["CLOUDINARY_PRIVATE_CDN"].to_s == 'true'
      )
    end

    set_config(new_config) if new_config
    yield(@@config) if block_given?

    @@config    
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
