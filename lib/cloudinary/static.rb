require 'find'
require 'time'
require 'set'
class Cloudinary::Static
  IGNORE_FILES = [".svn", "CVS", "RCS", ".git", ".hg"]
  SUPPORTED_IMAGES = [/\.(gif|jpe?g|png|bmp|ico|webp|wdp|jxr|jp2|svg|pdf)$/i]
  STATIC_IMAGE_DIRS = ["app/assets/images", "lib/assets/images", "vendor/assets/images", "public/images"]
  METADATA_FILE = ".cloudinary.static"
  METADATA_TRASH_FILE = ".cloudinary.static.trash"
  
  def self.discover
    ignore_files = Cloudinary.config.ignore_files || IGNORE_FILES 
    relative_dirs = Cloudinary.config.static_image_dirs || STATIC_IMAGE_DIRS
    dirs = relative_dirs.map{|dir| self.root.join(dir)}.select(&:exist?)
    dirs.each do
      |dir|
      dir.find do
        |path|
        file = path.basename.to_s
        if ignore_files.any?{|pattern| pattern.is_a?(String) ? pattern == file : file.match(pattern)}
          Find.prune
          next
        elsif path.directory?
          next
        elsif SUPPORTED_IMAGES.none?{|pattern| pattern.is_a?(String) ? pattern == file : file.match(pattern)}
          next          
        else
          relative_path = path.relative_path_from(self.root)
          public_path = path.relative_path_from(dir.dirname)
          yield(relative_path, public_path)
        end
      end
    end
  end

  def self.root
    Cloudinary.app_root
  end

  def self.metadata_file_path
    self.root.join(METADATA_FILE)
  end

  def self.metadata_trash_file_path
    self.root.join(METADATA_TRASH_FILE)
  end
  
  def self.metadata(metadata_file = metadata_file_path, hash=true) 
    metadata = []
    if File.exist?(metadata_file)
      IO.foreach(metadata_file) do
        |line|
        line.strip!
        next if line.blank?
        path, public_id, upload_time, version, width, height = line.split("\t")
        metadata << [path, {
          "public_id" => public_id, 
          "upload_time" => Time.at(upload_time.to_i).getutc, 
          "version" => version,
          "width" => width.to_i,
          "height" => height.to_i
        }]
      end
    end
    hash ? Hash[*metadata.flatten] : metadata
  end

  def self.sync(options={})
    options = options.clone
    delete_missing = options.delete(:delete_missing)
    metadata = self.metadata
    found_paths = Set.new
    found_public_ids = Set.new
    metadata_lines = []
    counts = { :not_changed => 0, :uploaded => 0, :deleted => 0, :not_found => 0}
    self.discover do
      |path, public_path|
      next if found_paths.include?(path)
      found_paths << path
      data = self.root.join(path).read(:mode=>"rb")
      ext = path.extname
      format = ext[1..-1]
      md5 = Digest::MD5.hexdigest(data)
      public_id = "#{public_path.basename(ext)}-#{md5}"
      found_public_ids << public_id
      current_metadata = metadata.delete(public_path.to_s)      
      if current_metadata && current_metadata["public_id"] == public_id # Signature match
        counts[:not_changed] += 1
        $stderr.print "#{public_path} - #{public_id} - Not changed\n"
        result = current_metadata
      else
        counts[:uploaded] += 1
        $stderr.print "#{public_path} - #{public_id} - Uploading\n"
        result = Cloudinary::Uploader.upload(Cloudinary::Blob.new(data, :original_filename=>path.to_s),
          options.merge(:format=>format, :public_id=>public_id, :type=>:asset)
        ).merge("upload_time"=>Time.now)        
      end
      metadata_lines << [public_path, public_id, result["upload_time"].to_i, result["version"], result["width"], result["height"]].join("\t")+"\n"
    end
    File.open(self.metadata_file_path, "w"){|f| f.print(metadata_lines.join)}
    metadata.to_a.each do |path, info|
      counts[:not_found] += 1
      $stderr.print "#{path} - #{info["public_id"]} - Not found\n"      
    end
    # Files no longer needed 
    trash = metadata.to_a + self.metadata(metadata_trash_file_path, false).reject{|public_path, info| found_public_ids.include?(info["public_id"])} 
    
    if delete_missing
      trash.each do
        |path, info|
        counts[:deleted] += 1
        $stderr.print "#{path} - #{info["public_id"]} - Deleting\n"
        Cloudinary::Uploader.destroy(info["public_id"], options.merge(:type=>:asset))
      end
      FileUtils.rm_f(self.metadata_trash_file_path)
    else
      # Add current removed file to the trash file.
      metadata_lines = trash.map do
        |public_path, info|
        [public_path, info["public_id"], info["upload_time"].to_i, info["version"], info["width"], info["height"]].join("\t")+"\n"
      end
      File.open(self.metadata_trash_file_path, "w"){|f| f.print(metadata_lines.join)}    
    end
    
    $stderr.print "\nCompleted syncing static resources to Cloudinary\n"
    $stderr.print counts.sort.reject{|k,v| v == 0}.map{|k,v| "#{v} #{k.to_s.gsub('_', ' ').capitalize}"}.join(", ") + "\n"
  end
end