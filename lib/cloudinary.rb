# Copyright Cloudinary
if RUBY_VERSION > "2"
  require "ostruct"
else
  require "cloudinary/ostruct2"
end

require "pathname"
require "yaml"
require "uri"
require "erb"
require "cloudinary/version"
require "cloudinary/exceptions"
require "cloudinary/missing"

module Cloudinary
  autoload :Utils, 'cloudinary/utils'
  autoload :Uploader, 'cloudinary/uploader'
  autoload :BaseConfig, "cloudinary/base_config"
  autoload :Config, "cloudinary/config"
  autoload :AccountConfig, "cloudinary/account_config"
  autoload :Request, "cloudinary/request"
  autoload :Api, "cloudinary/api"
  autoload :AccountApi, "cloudinary/account_api"
  autoload :Downloader, "cloudinary/downloader"
  autoload :Blob, "cloudinary/blob"
  autoload :PreloadedFile, "cloudinary/preloaded_file"
  autoload :Static, "cloudinary/static"
  autoload :CarrierWave, "cloudinary/carrier_wave"
  autoload :Search, "cloudinary/search"

  CF_SHARED_CDN         = "d3jpl91pxevbkh.cloudfront.net"
  AKAMAI_SHARED_CDN     = "res.cloudinary.com"
  OLD_AKAMAI_SHARED_CDN = "cloudinary-a.akamaihd.net"
  SHARED_CDN            = AKAMAI_SHARED_CDN

  USER_AGENT      = "CloudinaryRuby/#{VERSION} (Ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL})"
  @@user_platform = defined?(Rails.version) ? "Rails/#{Rails.version}" : ""

  # Add platform information to the USER_AGENT header
  # This is intended for platform information and not individual applications!
  def self.user_platform=(value)
    @@user_platform= value
  end

  def self.user_platform
    @@user_platform
  end

  def self.USER_AGENT
    if @@user_platform.empty?
      USER_AGENT
    else
      "#{@@user_platform} #{USER_AGENT}"
    end
  end

  FORMAT_ALIASES = {
    "jpeg" => "jpg",
    "jpe"  => "jpg",
    "tif"  => "tiff",
    "ps"   => "eps",
    "ept"  => "eps"
  }

  def self.config(new_config=nil, &block)
    manage_config(:@@config,
                  new_config,
                  -> { Config.new(config_dir.join("cloudinary.yml")) },
                  &block)
  end

  def self.account_config(new_config=nil, &block)
    manage_config(:@@account_config,
                  new_config,
                  -> { AccountConfig.new(config_dir.join("cloudinary.yml")) },
                  &block)
  end

  def self.config_from_url(url)
    config.load_from_url(url)
  end

  def self.config_from_account_url(url)
    account_config.load_from_url(url)
  end

  def self.app_root
    if defined? Rails::root
      # Rails 2.2 return String for Rails.root
      Rails.root.is_a?(Pathname) ? Rails.root : Pathname.new(Rails.root)
    else
      Pathname.new(".")
    end
  end

  private

  def self.config_env
    return ENV["CLOUDINARY_ENV"] if ENV["CLOUDINARY_ENV"]
    return Rails.env if defined? Rails::env
    nil
  end

  def self.config_dir
    return Pathname.new(ENV["CLOUDINARY_CONFIG_DIR"]) if ENV["CLOUDINARY_CONFIG_DIR"]
    self.app_root.join("config")
  end

  def self.set_config(new_config)
    new_config.each{|k,v| @@config.send(:"#{k}=", v) if !v.nil?}
  end

  def self.manage_config(var_name, new_config, config_factory, &block)
    # first, set class variable to `nil` if class variable is not yet defined
    # otherwise `class_variable_get(var_name)` will throw an error
    class_variable_set(var_name, nil) unless class_variable_defined?(var_name)
    # then set it to config provided by factory
    class_variable_set(var_name, config_factory.call) if class_variable_get(var_name).nil?

    class_variable_get(var_name).tap do |config|
      config.update(new_config) if new_config
      block.call(config) if block_given?
    end
  end

  private_class_method :manage_config
end
  # Prevent require loop if included after Rails is already initialized.
  require "cloudinary/helper" if defined?(::ActionView::Base)
  require "cloudinary/cloudinary_controller" if defined?(::ActionController::Base)
  require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)
  require "cloudinary/engine" if defined?(Rails) && defined?(Rails::Engine)

