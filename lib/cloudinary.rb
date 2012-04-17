# Copyright Cloudinary
require "ostruct"
require "cloudinary/version"
require "cloudinary/utils"
require "cloudinary/uploader"
require "cloudinary/downloader"
require "cloudinary/blob" 
require "cloudinary/static" if defined?(::ActiveSupport)
require 'active_support' 
require "cloudinary/missing"
require "cloudinary/carrier_wave" if defined?(::CarrierWave)
require "cloudinary/helper" if defined?(::ActionView::Base)
require "cloudinary/controller" if defined?(::ActionController::Base)
require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)

module Cloudinary  
  @@config = nil
  
  def self.config(new_config=nil)    
    @@config = new_config if new_config
    if block_given?
      @@config = OpenStruct.new
      yield(@@config)
    end 
    # Heroku support
    if @@config.nil? && ENV["CLOUDINARY_CLOUD_NAME"]
      @@config = OpenStruct.new(
        "cloud_name" => ENV["CLOUDINARY_CLOUD_NAME"],
        "api_key" => ENV["CLOUDINARY_API_KEY"],
        "api_secret" => ENV["CLOUDINARY_API_SECRET"],
        "secure_distribution" => ENV["CLOUDINARY_SECURE_DISTRIBUTION"],
        "private_cdn" => ENV["CLOUDINARY_PRIVATE_CDN"].to_s == 'true'
      )
    end    
    @@config ||= OpenStruct.new((YAML.load_file(Rails.root.join("config").join("cloudinary.yml"))[Rails.env] rescue {}))
  end
end
