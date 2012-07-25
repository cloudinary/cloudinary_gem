class Cloudinary::CarrierWave::Storage < ::CarrierWave::Storage::Abstract
  def store!(file)
    return if !uploader.enable_processing
    if uploader.is_main_uploader?
      case file
      when Cloudinary::CarrierWave::PreloadedCloudinaryFile 
        return store_cloudinary_version(file.version)
      when Cloudinary::CarrierWave::CloudinaryFile
        return nil # Nothing to do
      when Cloudinary::CarrierWave::RemoteFile
        data = file.uri.to_s
      else 
        data = file.file
        data.rewind if !file.is_path? && data.respond_to?(:rewind)
      end
            
      # This is the toplevel, need to upload the actual file.     
      params = uploader.transformation.dup
      params[:return_error] = true
      params[:format] = uploader.format
      params[:public_id] = uploader.my_public_id
      uploader.versions.values.each(&:tags) # Validate no tags in versions
      params[:tags] = uploader.tags if uploader.tags 
      eager_versions = uploader.versions.values.select(&:eager)
      params[:eager] = eager_versions.map{|version| [version.transformation, version.format]} if eager_versions.length > 0
      
      uploader.metadata = Cloudinary::Uploader.upload(data, params)
      if uploader.metadata["error"]
        raise Cloudinary::CarrierWave::UploadError.new(uploader.metadata["error"]["message"], uploader.metadata["error"]["http_code"])
      end
      
      store_cloudinary_version(uploader.metadata["version"]) if uploader.metadata["version"]
      # Will throw an exception on error
    else
      raise "nested versions are not allowed." if (uploader.class.version_names.length > 1)
      # Do nothing - versions are not handled locally.
    end
    nil
  end
  
  def store_cloudinary_version(version)
    name = "v#{version}/#{identifier.split("/").last}"
    model_class = uploader.model.class
    column = uploader.model.send(:_mounter, uploader.mounted_as).send(:serialization_column)
    if defined?(ActiveRecord::Base) && uploader.model.is_a?(ActiveRecord::Base)
      primary_key = model_class.primary_key.to_sym
      model_class.update_all({column=>name}, {primary_key=>uploader.model.send(primary_key)})
      uploader.model.send :write_attribute, column, name
    elsif defined?(Mongoid::Document) && uploader.model.is_a?(Mongoid::Document)
      # Mongoid support
      uploader.model.set(column, name)
    elsif model_class.respond_to?(:update_all) && uploader.model.respond_to?(:_id)
      model_class.where(:_id=>uploader.model._id).update_all(column=>name)
      uploader.model.send :write_attribute, column, name
    else
      raise "Only ActiveRecord and Mongoid are supported at the moment!"
    end
  end  
end
