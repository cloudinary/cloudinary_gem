require 'active_storage/blob_key'
require 'cloudinary/helper'

unless ActiveStorage::Blob.method_defined? :original_key
  class ActiveStorage::Blob
    alias_method :original_key, :key

    def key
      original_key
      ActiveStorage::BlobKey.new(@attributes.as_json)
    end
  end
end

module ActiveStorage
  class Service::CloudinaryService < Service
    attr_reader :upload_options

    def initialize(**options)
      @options = options
      @helper = ActionView::Base.new
    end

    def upload(key, io, filename: nil, checksum: nil, **options)
      instrument :upload, key: key, checksum: checksum do
        begin
          extra_headers = checksum.nil? ? {} : {'Content-md5': checksum}
          options = @options.merge(options)
          @image_meta = Cloudinary::Uploader.upload(
            io,
            public_id: public_id(key),
            resource_type: resource_type(io, key),
            context: {active_storage_key: key, checksum: checksum},
            extra_headers: extra_headers,
            **options
          )

        end
      end
    end

    def url(key, filename: nil, content_type: '', **options)
      instrument :url, key: key do |payload|
        url = Cloudinary::Utils.cloudinary_url(
          public_id(key),
          resource_type: resource_type(nil, key),
          format: ext_for_content_type(content_type),
          **@options.merge(options.symbolize_keys)
        )
        payload[:url] = url

        url
      end
    end

    def url_for_direct_upload(key, **options)
      instrument :url, key: key do |payload|
        options = {:resource_type => resource_type(nil, key)}.merge(@options.merge(options.symbolize_keys))
        options[:public_id] = public_id(key)
        options[:context] = {active_storage_key: key}
        options.delete(:file)
        payload[:url] = api_uri("direct_upload", options)
      end
    end

    def headers_for_direct_upload(key, content_type:, checksum:, **)
      {
        "Content-Type" => content_type,
        "Content-MD5" => checksum,
        # "Access-Control-Allow-Origin" => "localhost"
      }
    end

    def delete(key)
      instrument :delete, key: key do
        Cloudinary::Uploader.destroy public_id(key), resource_type: resource_type(nil, key)
      end
    end

    def delete_prefixed(prefix)
      # instrument :delete_prefixed, prefix: prefix do
      #   Cloudinary::Api.delete_resources_by_prefix(prefix)
      # end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        begin
          Cloudinary::Api.resource public_id(key), resource_type: resource_type(nil, key)
          true
        rescue Cloudinary::Api::NotFound => e
          false
        end
      end
    end

    def download(key, &block)
      url = Cloudinary::Utils.unsigned_download_url(public_id(key), resource_type: resource_type(nil, key))
      uri = URI(url)
      if block_given?
        instrument :streaming_download, key: key do
          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new uri
            http.request request do |response|
              response.read_body &block
            end

          end
        end
      else
        instrument :download, key: key do
          puts "download URL #{url}"
          res = Net::HTTP::get_response(uri)
          res.body
        end
      end
    end

    # Return the partial content in the byte +range+ of the file at the +key+.
    def download_chunk(key, range)
      url = Cloudinary::Utils.unsigned_download_url(public_id(key), resource_type: resource_type(nil, key))
      uri = URI(url)
      instrument :download, key: key do
        puts "download URL #{url}"
        req = Net::HTTP::Get.new(uri)
        req['range'] = "bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}"
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end
        res.body.force_encoding(Encoding::BINARY)
      end

    end

    private

    def api_uri(action, options)
      base_url = Cloudinary::Utils.cloudinary_api_url(action, options)
      cloudinary_params = Cloudinary::Uploader.build_upload_params(options)

      cloudinary_params.reject! {|k, v| Cloudinary::Utils.safe_blank?(v)}
      unless options[:unsigned]
        cloudinary_params = Cloudinary::Utils.sign_request(cloudinary_params, options)
      end
      "#{base_url}?#{cloudinary_params.to_query}"
    end

    def ext_for_content_type(content_type)
      @formats ||= Hash.new do |h, key|
        ext = Rack::Mime::MIME_TYPES.invert[key]
        h[key] = ext.slice(1..-1) unless ext.nil?
      end
      @formats[content_type]
    end

    def public_id(key)
      if key.respond_to? :attributes
        key.attributes[:filename] # TODO match server handling of filename to public_id
      else
        key
      end
    end

    def resource_type(io, key = "")
      return 'image' unless key.respond_to? :attributes
      options = key.attributes
      content_type = options[:content_type] || (io.nil? ? '' : Marcel::MimeType.for(io))
      case content_type.split('/')[0]
      when 'image'
        'image'
      when 'video'
        'video'
      when ''
        'image'
      when 'text'
        'raw'
      else
        'image'
      end
    end


  end
end
