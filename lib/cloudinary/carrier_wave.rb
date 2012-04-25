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
    base.send(:attr_accessor, :metadata)
        
    override_in_versions(base, :filename, :blank?, :stored_version)
  end  
  
  def stored_version
    @stored_version
  end
  
  def retrieve_from_store!(identifier)
    if identifier.blank?
      @file = @version = @stored_public_id = nil
    else
      @file = CloudinaryFile.new(identifier, self)
      @stored_public_id = @file.public_id
      @stored_version = @file.version
    end
  end  
           
  def url(*args)
    if args.first && !args.first.is_a?(Hash)
      super
    else
      return super if self.blank?
      options = args.extract_options!
      options = self.transformation.merge(options) if self.version_name.present?
      public_id = Cloudinary::CarrierWave.split_format(self.filename).first
      Cloudinary::Utils.cloudinary_url(public_id, {:format=>self.format, :version=>self.stored_version}.merge(options))
    end
  end
      
  def filename
    self.blank? ? nil : [self.my_public_id, self.format].join(".")
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
  
  # Should removed files be removed from Cloudinary as well. Can be overridden.
  def delete_remote?
    true
  end
  
  class CloudinaryFile
    attr_reader :identifier, :public_id, :filename, :format, :version
    def initialize(identifier, uploader)
      @uploader = uploader
      @identifier = identifier
      version, @filename = @identifier.split("/")
      @version = version[1..-1] # remove 'v' prefix 
      @public_id, @format = Cloudinary::CarrierWave.split_format(@filename)      
    end
    
    def delete
      Cloudinary::Uploader.destroy(self.public_id) if @uploader.delete_remote?        
    end
  end

  def self.split_format(identifier)
    last_dot = identifier.rindex(".")
    return [public_id, nil] if last_dot.nil?
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
