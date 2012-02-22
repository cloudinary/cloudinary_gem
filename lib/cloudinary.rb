# Copyright Cloudinary
require "ostruct"
require "cloudinary/version"
require "cloudinary/utils"
require "cloudinary/uploader"
require "cloudinary/downloader"
require "cloudinary/migrator"  
require "cloudinary/blob" 
require 'active_support' 
if defined?(::CarrierWave)
  require "cloudinary/carrier_wave"
end  

if defined?(::ActionView::Base)
  require "cloudinary/helper"  
end

if !nil.respond_to?(:blank?)
class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class NilClass #:nodoc:
  def blank?
    true
  end
end

class FalseClass #:nodoc:
  def blank?
    true
  end
end

class TrueClass #:nodoc:
  def blank?
    false
  end
end

class Array #:nodoc:
  alias_method :blank?, :empty?
end

class Hash #:nodoc:
  alias_method :blank?, :empty?
end

class String #:nodoc:
  def blank?
    self !~ /\S/
  end
end

class Numeric #:nodoc:
  def blank?
    false
  end
end  
end

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
