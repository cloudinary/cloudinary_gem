# Copyright Cloudinary
require 'pp'
module Cloudinary::CarrierWave
  CLOUDINARY_PATH = /^([^\/]+)\/upload\/v(\d+)\/([^\/]+)#([^\/]+)$/
  
  class UploadError < StandardError
    attr_reader :http_code
    def initialize(message, http_code)
      super(message)
      @http_code = http_code
    end
  end
  
  module ClassMethods
    def eager
      process :eager => true
    end
    
    def convert(format)
      process :convert => format
    end

    def resize_to_limit(width, height)
      process :resize_to_limit => [width, height]
    end

    def resize_to_fit(width, height)
      process :resize_to_fit => [width, height]
    end

    def resize_to_fill(width, height, gravity="Center")
      process :resize_to_fill => [width, height, gravity]
    end

    def resize_and_pad(width, height, background=:transparent, gravity="Center")
      process :resize_and_pad => [width, height, background, gravity]
    end    

    def scale(width, height)
      process :scale => [width, height]
    end    

    def crop(width, height, gravity="Center")
      process :crop => [width, height, gravity]
    end

    def cloudinary_transformation(options)
      process :cloudinary_transformation => options
    end
    
    def tags(*tags)
      process :tags=>tags
    end
  end
  
  def self.included(base)
    base.storage Cloudinary::CarrierWave::Storage
    base.extend ClassMethods
    base.send(:attr_accessor, :metadata)
    base.send(:alias_method, :original_cache!, :cache!)
    base.send(:alias_method, :original_cache_name, :cache_name)
    base.send(:alias_method, :original_retrieve_from_cache!, :retrieve_from_cache!)
    base.send(:include, Override)
  end
  
  module Override
    def cache!(new_file)
      if new_file.is_a?(String) && new_file.match(CLOUDINARY_PATH)
        @file = CloudinaryFile.new(new_file)
        self.original_filename = @cache_id = @my_filename = @filename = @file.original_filename
      else
        original_cache!(new_file)
      end
    end

    def retrieve_from_cache!(new_file)
      if new_file.is_a?(String) && new_file.match(CLOUDINARY_PATH)
        @file = CloudinaryFile.new(new_file)
        self.original_filename = @cache_id = @my_filename = @filename = @file.original_filename
      else
        original_retrieve_from_cache!(new_file)
      end
    end
    
    def cache_name
      if @file.is_a?(CloudinaryFile)
        return @file.to_s
      else
        return original_cache_name
      end
    end
  end
      
  def set_or_yell(hash, attr, value)
    raise "conflicting transformation on #{attr} #{value}!=#{hash[attr]}" if hash[attr]
    hash[attr] = value
  end
  
  def transformation
    return @transformation if @transformation
    transformation = {}
    self.class.processors.each do
      |name, args|
      case name
      when :convert # Do nothing. This is handled by format
      when :resize_to_limit 
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :crop, :limit)
      when :resize_to_fit 
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :crop, :fit)
      when :resize_to_fill
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :gravity, args[2].to_s.downcase)
        set_or_yell(transformation, :crop, :fill)
      when :resize_to_pad
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :gravity, args[3].to_s.downcase)
        set_or_yell(transformation, :crop, :pad)
      when :scale 
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :crop, :scale)
      when :crop
        set_or_yell(transformation, :width, args[0])    
        set_or_yell(transformation, :height, args[1])
        set_or_yell(transformation, :gravity, args[2].to_s.downcase)
        set_or_yell(transformation, :crop, :crop)
      when :cloudinary_transformation
        args.each do
          |attr, value|        
          set_or_yell(transformation, attr, value)
        end
      end
    end
    @transformation = transformation
    @transformation     
  end
  
  def eager
    @eager ||= self.class.processors.any?{|processor| processor[0] == :eager}
  end

  def tags
    @tags ||= self.class.processors.select{|processor| processor[0] == :tags}.map(&:last).first
  end
  
  def format
    format_processor = self.class.processors.find{|processor| processor[0] == :convert}
    if format_processor
      if format_processor[1].is_a?(Array)
        return format_processor[1][0]
      end  
      return format_processor[1]
    end
    the_filename = original_filename || stored_filename
    return the_filename.split(".").last if the_filename.include?(".")
    "png" # TODO Default format?
  end
  
  def url(*args)
    if args.first && !args.first.is_a?(Hash)
      super
    else
      return nil if self.my_identifier.blank?
      options = args.extract_options!
      options = options.merge(self.class.version_names.blank? ? {} : self.transformation)
      Cloudinary::Utils.cloudinary_url(self.my_filename, options)
    end
  end

  def process!(new_file=nil)
    # Do nothing
  end

  def stored_filename
    @stored_filename = model.read_uploader(mounted_as) if @stored_filename.blank?
    @stored_filename
  end  

  def my_filename
    @my_filename ||= stored_filename.present? ? stored_filename : ("#{self.public_id}.#{self.format}")
  end
    
  def public_id
    return @public_id if @public_id
    if stored_filename.present?
      last_dot = stored_filename.rindex(".")
      @public_id = last_dot ? stored_filename[0, last_dot] : stored_filename 
    end    
    @public_id ||= Cloudinary::Utils.random_public_id
  end  
  
  def download!(uri)
    uri = process_uri(uri)
    self.original_filename = @cache_id = @filename = File.basename(uri.path).gsub(/[^a-zA-Z0-9\.\-\+_]/, '')
    @file = RemoteFile.new(uri, @filename)
  end
  
  def my_identifier
    (self.filename || self.stored_filename.present?) ? self.my_filename : nil    
  end
  
  class RemoveableFile
    def initialize(identifier)
      @public_id = identifier.split("/").last.split(".").first
    end
    
    def delete
      Cloudinary::Uploader.destroy(@public_id)
    end
  end
  
  class RemoteFile
    attr_reader :uri, :original_filename
    def initialize(uri, filename)
      @uri = uri
      @original_filename = filename
    end
    
    def delete
      # Do nothing. This is a virtual file.
    end
  end
  
  class CloudinaryFile
    attr_reader :original_filename, :version
    def initialize(file_info)
      resource_type, @version, @original_filename, @signature = file_info.scan(CLOUDINARY_PATH).first
      raise "Cloudinary CarrierWave integration supports images only" if resource_type != "image"
      public_id = @original_filename[0..(@original_filename.rindex(".")-1)]
      expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>public_id, :version=>version}, Cloudinary.config.api_secret)
      if @signature != expected_signature
        raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.cloudinary_signature_error", :public_id=>public_id, :default=>"Invalid signature for #{public_id}")
      end
    end
    
    def to_s
      "image/upload/v#{@version}/#{@original_filename}##{@signature}"
    end

    def delete
      # Do nothing. This is a virtual file.
    end
  end
  
  class Storage < ::CarrierWave::Storage::Abstract
    def store!(file)
      # Moved to identifier...
      if uploader.class.version_names.blank?
        return store_cloudinary_version(file.version) if file.is_a?(CloudinaryFile)
        
        # This is the toplevel, need to upload the actual file.     
        params = uploader.transformation.dup
        params[:return_error] = true
        params[:format] = uploader.format
        params[:public_id] = uploader.public_id.split("/").last
        params[:tags] = uploader.tags if uploader.tags 
        eager_versions = uploader.versions.values.select(&:eager)
        params[:eager] = eager_versions.map{|version| [version.transformation, version.format]} if eager_versions.length > 0
        
        data = nil
        if (file.is_a?(RemoteFile))
          data = file.uri.to_s
        else
          data = file.file
          data.rewind if !file.is_path? && data.respond_to?(:rewind)
        end
        uploader.metadata = Cloudinary::Uploader.upload(data, params)
        if uploader.metadata["error"]
          raise UploadError.new(uploader.metadata["error"]["message"], uploader.metadata["error"]["http_code"])
        end
        
        store_cloudinary_version(uploader.metadata["version"]) if uploader.metadata["version"]
        # Will throw an exception on error
      else
        raise "nested versions are not allowed." if (uploader.class.version_names.length > 1)
        # Do nothing
      end
      nil
    end
    
    def store_cloudinary_version(version)
      name = "v#{version}/#{identifier.split("/").last}"
      model_class = uploader.model.class
      if defined?(ActiveRecord::Base) && uploader.model.is_a?(ActiveRecord::Base)
        primary_key = model_class.primary_key.to_sym
        model_class.update_all({uploader.mounted_as=>name}, {primary_key=>uploader.model.send(primary_key)})
        uploader.model.send :write_attribute, uploader.mounted_as, name
      elsif model_class.respond_to?(:update_all) && uploader.model.respond_to?(:_id)
        # Mongoid support
        model_class.where(:_id=>uploader.model._id).update_all(uploader.mounted_as=>name)
        uploader.model.send :write_attribute, uploader.mounted_as, name
      else
        raise "Only ActiveRecord and Mongoid are supported at the moment!"
      end
    end
    
    def retrieve!(identifier)
      if uploader.class.version_names.blank?
        return RemoveableFile.new(identifier)
      else
        return nil # Version files should not be deleted.
      end      
    end 
    
    def identifier
      uploader.my_identifier      
    end   
  end
end
