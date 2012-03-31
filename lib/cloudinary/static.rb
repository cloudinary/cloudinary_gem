require 'find'
class Cloudinary::Static
  IGNORE_FILES = [".svn", "CVS", "RCS", ".git", ".hg", /^.htaccess/]
  STATIC_IMAGE_DIRS = ["app/assets/images", "public/images"]
  METADATA_FILE = ".cloudinary.static"
  
  def self.discover
    ignore_files = Cloudinary.config.ignore_files || IGNORE_FILES 
    relative_dirs = Cloudinary.config.statis_image_dirs || STATIC_IMAGE_DIRS
    dirs = relative_dirs.map{|dir| Rails.root.join(dir)}.select(&:exist?)
    dirs.each do
      |dir|
      dir.find do
        |path|
        file = path.basename.to_s
        if IGNORE_FILES.any?{|pattern| pattern.is_a?(String) ? pattern == file : file.match(pattern)}
          Find.prune
          next
        elsif path.directory?
          next
        else
          relative_path = path.relative_path_from(Rails.root)
          public_path = path.relative_path_from(dir.dirname)
          yield(relative_path, public_path)
        end
      end
    end
  end
  
  UTC = ActiveSupport::TimeZone["UTC"]
  
  def self.metadata_file_path
    Rails.root.join(METADATA_FILE)
  end
  
  def self.metadata 
    metadata = {}
    if File.exist?(metadata_file_path)
      IO.foreach(metadata_file_path) do
        |line|
        line.strip!
        next if line.blank?
        path, public_id, upload_time, version, width, height = line.split("\t")
        metadata[path] = {
          "public_id" => public_id, 
          "upload_time" => UTC.at(upload_time.to_i), 
          "version" => version,
          "width" => width.to_i,
          "height" => height.to_i
        }
      end
    end
    metadata
  end

  def self.sync(options={})
    prefix = Pathname.new("static")
    options = options.clone
    delete_missing = options.delete(:delete_missing)
    metadata = self.metadata
    found = Set.new
    metadata_lines = []
    self.discover do
      |path, public_path|
      next if found.include?(path)
      found << path
      data = Rails.root.join(path).read(:mode=>"rb")
      ext = path.extname
      format = ext[1..-1]
      md5 = Digest::MD5.hexdigest(data)
      public_id = prefix.join(public_path)
      public_id = "#{public_id.dirname}/#{public_id.basename(ext)}-#{md5}"
      current_metadata = metadata.delete(public_path.to_s)      
      if current_metadata && current_metadata["public_id"] == public_id # Signature match
        result = current_metadata
      else
        result = Cloudinary::Uploader.upload(Cloudinary::Blob.new(data, :original_filename=>path.to_s),
          options.merge(:format=>format, :public_id=>public_id)
        )
      end
      metadata_lines << [public_path, public_id, Time.now.to_i, result["version"], result["width"], result["height"]].join("\t")+"\n"
    end
    File.open(self.metadata_file_path, "w"){|f| f.print(metadata_lines.join)}
    # TODO if delete missing is false, should we keep the metadata?
    if delete_missing
      metadata.each do
        |path, info|
        Cloudinary::Uploader.destroy(info["public_id"], options)
      end
    end
  end
end