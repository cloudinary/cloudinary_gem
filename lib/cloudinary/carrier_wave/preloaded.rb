# Copyright Cloudinary
# Support for store in CarrierWave files that were preloaded to cloudinary (e.g., by javascript)
# Field value must be in the format:  "image/upload/v<version>/#<public_id>.<format>#<signature>"
# Where signature is the cloduinary API signature on the public_id and version.
module Cloudinary::CarrierWave
  PRELOADED_CLOUDINARY_PATH = /^([^\/]+)\/upload\/v(\d+)\/([^\/]+)#([^\/]+)$/

  def cache!(new_file)
    if new_file.is_a?(String) && new_file.match(PRELOADED_CLOUDINARY_PATH)
      @file = PreloadedCloudinaryFile.new(new_file)
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = @file.original_filename
      @cache_id = "unused" # must not be blank 
    else
      super
    end
  end

  def retrieve_from_cache!(new_file)
    if new_file.is_a?(String) && new_file.match(PRELOADED_CLOUDINARY_PATH)
      @file = PreloadedCloudinaryFile.new(new_file)
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = @file.original_filename
      @cache_id = "unused" # must not be blank 
    else
      super
    end
  end
  
  def cache_name
    return @file.is_a?(PreloadedCloudinaryFile) ? @file.to_s : super
  end
  
  class PreloadedCloudinaryFile
    attr_reader :original_filename, :version, :public_id, :signature
    def initialize(file_info)
      resource_type, @version, @original_filename, @signature = file_info.scan(PRELOADED_CLOUDINARY_PATH).first
      raise "Cloudinary CarrierWave integration supports images only" if resource_type != "image"
      @public_id = @original_filename[0..(@original_filename.rindex(".")-1)]
      expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>public_id, :version=>version}, Cloudinary.config.api_secret)
      if @signature != expected_signature
        raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.cloudinary_signature_error", :public_id=>public_id, :default=>"Invalid signature for #{public_id}")
      end      
    end
    
    def identifier
      "v#{version}/#{original_filename}"
    end
    
    def to_s
      "image/upload/v#{version}/#{original_filename}##{signature}"
    end

    def delete
      # Do nothing. This is a virtual file.
    end
  end  
end