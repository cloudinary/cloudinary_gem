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
  autoload :Api, "cloudinary/api"
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

  @@config = nil

  def self.config(new_config=nil)
    first_time = @@config.nil?
    @@config   ||= OpenStruct.new((YAML.load(ERB.new(IO.read(config_dir.join("cloudinary.yml"))).result)[config_env] rescue {}))

    config_from_env if first_time

    set_config(new_config) if new_config
    yield(@@config) if block_given?

    @@config
  end

  def self.config_from_url(url)
    @@config ||= OpenStruct.new
    return unless url && !url.empty?
    uri = URI.parse(url)
    if !uri.scheme || "cloudinary" != uri.scheme.downcase
      raise(CloudinaryException,
        "Invalid CLOUDINARY_URL scheme. Expecting to start with 'cloudinary://'")
    end
    set_config(
      "cloud_name"          => uri.host,
      "api_key"             => uri.user,
      "api_secret"          => uri.password,
      "private_cdn"         => !uri.path.blank?,
      "secure_distribution" => uri.path[1..-1]
    )
    uri.query.to_s.split("&").each do
    |param|
      key, value = param.split("=")
      if isNestedKey? key
        putNestedKey key, value
      else
        set_config(key => Utils.smart_unescape(value))
      end
    end
  end

  def self.putNestedKey(key, value)
    chain   = key.split(/[\[\]]+/).reject { |i| i.empty? }
    outer   = @@config
    lastKey = chain.pop()
    chain.each do |innerKey|
      inner = outer[innerKey]
      if inner.nil?
        inner           = OpenStruct.new
        outer[innerKey] = inner
      end
      outer = inner
    end
    outer[lastKey] = value
  end


  def self.isNestedKey?(key)
    /\w+\[\w+\]/ =~ key
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

  def self.config_from_env
    # Heroku support
    if ENV["CLOUDINARY_CLOUD_NAME"]
      config_keys = ENV.keys.select! { |key| key.start_with? "CLOUDINARY_" }
      config_keys -= ["CLOUDINARY_URL"] # ignore it when explicit options are passed
      config_keys.each do |full_key|
        conf_key = full_key["CLOUDINARY_".length..-1].downcase # convert "CLOUDINARY_CONFIG_NAME" to "config_name"
        conf_val = ENV[full_key]
        conf_val = conf_val == 'true' if %w[true false].include?(conf_val) # cast relevant boolean values
        set_config(conf_key => conf_val)
      end
    elsif ENV["CLOUDINARY_URL"]
      config_from_url(ENV["CLOUDINARY_URL"])
    end
  end

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
end
  # Prevent require loop if included after Rails is already initialized.
  require "cloudinary/helper" if defined?(::ActionView::Base)
  require "cloudinary/cloudinary_controller" if defined?(::ActionController::Base)
  require "cloudinary/railtie" if defined?(Rails) && defined?(Rails::Railtie)
  require "cloudinary/engine" if defined?(Rails) && defined?(Rails::Engine)

