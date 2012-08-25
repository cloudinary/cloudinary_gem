class Cloudinary::PreloadedFile
  PRELOADED_CLOUDINARY_PATH = /^([^\/]+)\/([^\/]+)\/v(\d+)\/([^\/]+)#([^\/]+)$/

  attr_reader :filename, :version, :public_id, :signature, :resource_type, :type
  def initialize(file_info)
    @resource_type, @type, @version, @filename, @signature = file_info.scan(PRELOADED_CLOUDINARY_PATH).first    
    @public_id = @resource_type == "image" ? @filename[0..(@filename.rindex(".")-1)] : @filename
  end
  
  def valid?
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>public_id, :version=>version}, Cloudinary.config.api_secret)
    @signature == expected_signature
  end
  
  def identifier
    "v#{version}/#{filename}"
  end
  
  def to_s
    "#{resource_type}/#{type}/v#{version}/#{filename}##{signature}"
  end
  
end