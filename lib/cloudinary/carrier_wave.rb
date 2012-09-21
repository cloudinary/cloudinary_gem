# Copyright Cloudinary
require 'cloudinary/carrier_wave/process'
require 'cloudinary/carrier_wave/error'
require 'cloudinary/carrier_wave/remote'
require 'cloudinary/carrier_wave/preloaded'
require 'cloudinary/carrier_wave/storage'

module Cloudinary::CarrierWave

  def self.included(base)
    base.storage Cloudinary::CarrierWave::Storage
    base.extend ClassMethods
    base.class_attribute :storage_type, :metadata
    base.send(:attr_reader, :stored_version)
    override_in_versions(base, :blank?, :full_public_id, :all_versions_processors)
  end  
    
  def is_main_uploader?
    self.class.version_names.blank?
  end
  
  def retrieve_from_store!(identifier)
    if identifier.blank?
      @file = @stored_version = @stored_public_id = nil
      self.original_filename = nil
    else
      @file = CloudinaryFile.new(identifier, self)
      @public_id = @stored_public_id = @file.public_id
      @stored_version = @file.version
      self.original_filename = sanitize(@file.filename)
    end
  end  

  def url(*args)
    if args.first && !args.first.is_a?(Hash)
      super
    else
      if self.blank?
        url = self.default_url
        return url if !url.blank?
        public_id = self.default_public_id
        return nil if public_id.nil?
      else
        public_id = self.full_public_id
      end      
      options = args.extract_options!
      options = self.transformation.merge(options) if self.version_name.present?
      
      resource_type = Cloudinary::Utils.resource_type_for_format(filename)
      Cloudinary::Utils.cloudinary_url(public_id, {:format=>self.format, :resource_type=>resource_type, :type=>self.storage_type}.merge(options))
    end
  end

  def full_public_id
    return nil if self.blank?
    return self.my_public_id if self.stored_version.blank?
    return "v#{self.stored_version}/#{self.my_public_id}"
  end    

  def filename
    return nil if self.blank?
    return [self.full_public_id, self.format].join(".")
  end

  # default public_id to use if no uploaded file. Override with public_id of an uploaded image if you want a default image.
  def default_public_id
    nil
  end
      
  # public_id to use for uploaded file. Can be overridden by caller. Random public_id will be used otherwise.  
  def public_id
    nil
  end
  
  # If the user overrode public_id, that should be used, even if it's different from current public_id in the database.
  # Otherwise, try to use public_id from the database.
  # Otherwise, generate a new random public_id
  def my_public_id
    @public_id ||= self.public_id 
    @public_id ||= @stored_public_id
    @public_id ||= Cloudinary::Utils.random_public_id
  end  

  def recreate_versions!
    # Do nothing
  end
  
  def cache_versions!(new_file=nil)
    # Do nothing
  end
  
  def process!(new_file=nil)
    # Do nothing
  end
  
  SANITIZE_REGEXP = CarrierWave::SanitizedFile.respond_to?(:sanitize_regexp) ? CarrierWave::SanitizedFile.sanitize_regexp : /[^a-zA-Z0-9\.\-\+_]/
  def sanitize(filename)
    return nil if filename.nil?
    filename.gsub(SANITIZE_REGEXP, '_')
  end
  
  # Should removed files be removed from Cloudinary as well. Can be overridden.
  def delete_remote?
    true
  end
  
  class CloudinaryFile
    attr_reader :identifier, :public_id, :filename, :format, :version, :storage_type, :resource_type
    def initialize(identifier, uploader)
      @uploader = uploader
      @identifier = identifier

      if @identifier.include?("/")
        version, @filename = @identifier.split("/")
        @version = version[1..-1] # remove 'v' prefix
      else
        @filename = @identifier
        @version = nil 
      end

      @storage_type = uploader.class.storage_type
      @resource_type = Cloudinary::Utils.resource_type_for_format(@filename)      
      @public_id, @format = Cloudinary::CarrierWave.split_format(@filename)      
    end
    
    def delete
      Cloudinary::Uploader.destroy(self.public_id, :type=>self.storage_type, :resource_type=>self.resource_type) if @uploader.delete_remote?        
    end
    
    def exists?
      Cloudinary::Uploader.exists?(self.identifier, :type=>self.storage_type, :resource_type=>self.resource_type)
    end
    
    def read(options={})
      parameters={:type=>self.storage_type, :resource_type=>self.resource_type}.merge(options)
      Cloudinary::Downloader.download(self.identifier, parameters)
    end

  end

  def self.split_format(identifier)
    last_dot = identifier.rindex(".")
    return [identifier, nil] if last_dot.nil?
    public_id = identifier[0, last_dot]
    format = identifier[last_dot+1..-1]
    return [public_id, format]    
  end

  # For the given methods - versions should call the main uploader method
  def self.override_in_versions(base, *methods)
    methods.each do
      |method|
      base.send :define_method, method do
        return super() if self.version_name.blank?
        uploader = self.model.send(self.mounted_as)
        uploader.send(method)    
      end
    end    
  end
end
