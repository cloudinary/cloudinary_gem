# Copyright Cloudinary
# Support for store in CarrierWave files that were preloaded to cloudinary (e.g., by javascript)
# Field value must be in the format:  "image/upload/v<version>/#<public_id>.<format>#<signature>"
# Where signature is the cloduinary API signature on the public_id and version.
module Cloudinary::CarrierWave
  PRELOADED_CLOUDINARY_PATH = Cloudinary::PreloadedFile::PRELOADED_CLOUDINARY_PATH

  def cache!(new_file)
    if new_file.is_a?(String) && new_file.match(PRELOADED_CLOUDINARY_PATH)
      @file = PreloadedCloudinaryFile.new(new_file)
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = sanitize(@file.original_filename)
      @cache_id = "unused" # must not be blank 
    else
      super
      @public_id = nil # allow overriding public_id
    end
  end

  def retrieve_from_cache!(new_file)
    if new_file.is_a?(String) && new_file.match(PRELOADED_CLOUDINARY_PATH)
      @file = PreloadedCloudinaryFile.new(new_file)
      @stored_version = @file.version
      @public_id = @stored_public_id = @file.public_id
      self.original_filename = sanitize(@file.original_filename)
      @cache_id = "unused" # must not be blank 
    else
      super
      @public_id = nil # allow overriding public_id
    end
  end
  
  def cache_name
    return @file.is_a?(PreloadedCloudinaryFile) ? @file.to_s : super
  end
  
  class PreloadedCloudinaryFile < Cloudinary::PreloadedFile
    def initialize(file_info)
      super
      if !valid?
        raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.cloudinary_signature_error", :public_id=>public_id, :default=>"Invalid signature for #{public_id}")
      end
    end    

    def delete
      # Do nothing. This is a virtual file.
    end
    
    def original_filename
      self.filename
    end
  end
end