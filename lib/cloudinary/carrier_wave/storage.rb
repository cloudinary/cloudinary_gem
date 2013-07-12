class Cloudinary::CarrierWave::Storage < ::CarrierWave::Storage::Abstract

  def store!(file)
    return if !uploader.enable_processing
    if uploader.is_main_uploader?
      case file
      when Cloudinary::CarrierWave::PreloadedCloudinaryFile
        storage_type = uploader.class.storage_type || "upload"
        raise CloudinaryException, "Uploader configured for type #{storage_type} but resource of type #{file.type} given." if storage_type != file.type
        if uploader.public_id && uploader.auto_rename_preloaded?
          @stored_version = file.version
          uploader.rename(nil, true)
        else
          store_cloudinary_identifier(file.version, file.filename)
        end
        return
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
      params[:type]=uploader.class.storage_type

      params[:resource_type] ||= :auto

      uploader.metadata = Cloudinary::Uploader.upload(data, params)
      if uploader.metadata["error"]
        raise Cloudinary::CarrierWave::UploadError.new(uploader.metadata["error"]["message"], uploader.metadata["error"]["http_code"])
      end

      if uploader.metadata["version"]
        filename = [uploader.metadata["public_id"], uploader.metadata["format"]].reject(&:blank?).join(".")
        store_cloudinary_identifier(uploader.metadata["version"], filename)
      end
      # Will throw an exception on error
    else
      raise CloudinaryException, "nested versions are not allowed." if (uploader.class.version_names.length > 1)
      # Do nothing - versions are not handled locally.
    end
    nil
  end

  # @deprecated For backward compatibility
  def store_cloudinary_version(version)
    if identifier.match(%r(^(v[0-9]+)/(.*)))
      filename = $2
    else
      filename = identifier
    end

    store_cloudinary_identifier(version, filename)
  end

  def store_cloudinary_identifier(version, filename)
    name = "v#{version}/#{filename}"
    model_class = uploader.model.class
    column = uploader.model.send(:_mounter, uploader.mounted_as).send(:serialization_column)
    if defined?(ActiveRecord::Base) && uploader.model.is_a?(ActiveRecord::Base)
      primary_key = model_class.primary_key.to_sym
      if Rails.version >= "3.0"
        model_class.where(primary_key=>uploader.model.send(primary_key)).update_all(column=>name)
      else
        model_class.update_all({column=>name}, {primary_key=>uploader.model.send(primary_key)})
      end
      uploader.model.send :write_attribute, column, name
    elsif defined?(Mongoid::Document) && uploader.model.is_a?(Mongoid::Document)
      # Mongoid support
      if Mongoid::VERSION.split(".").first.to_i >= 4
        uploader.model.set(:"#{column}" => name)
      else
        uploader.model.set(column, name)
      end
    elsif model_class.respond_to?(:update_all) && uploader.model.respond_to?(:_id)
      model_class.where(:_id=>uploader.model._id).update_all(column=>name)
      uploader.model.send :write_attribute, column, name
    else
      raise CloudinaryException, "Only ActiveRecord and Mongoid are supported at the moment!"
    end
  end
end
