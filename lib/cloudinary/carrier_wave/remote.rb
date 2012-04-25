module Cloudinary::CarrierWave
  def download!(uri)
    if respond_to?(:process_uri)
      uri = process_uri(uri)
    else # Backward compatibility with old CarrierWave
      uri = URI.parse(URI.escape(URI.unescape(uri)))
    end
    self.original_filename = @cache_id = @filename = File.basename(uri.path).gsub(/[^a-zA-Z0-9\.\-\+_]/, '')
    @file = RemoteFile.new(uri, @filename)
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
end  