if RUBY_VERSION > '2.2.2'
  require 'spec_helper'

  AS_TAG = "active_storage_" + SUFFIX
  BASENAME = File.basename(TEST_IMG, '.*')

  CONFIGURATION_PATH = Pathname.new(File.expand_path("service/configurations.yml", __dir__))
  SERVICE = ActiveStorage::Service.configure(:cloudinary, SERVICE_CONFIGURATIONS)

  describe 'active_storage' do
    let(:key) {ActiveStorage::BlobKey.new({key: SecureRandom.base58(24), filename: BASENAME})}

    before :all do
      @key = ActiveStorage::BlobKey.new key: SecureRandom.base58(24), filename: BASENAME
      @service = self.class.const_get(:SERVICE)
      @service.upload @key, TEST_IMG, tags: [TEST_TAG, TIMESTAMP_TAG, AS_TAG]
    end

    after :all do
      Cloudinary::Api.delete_resources_by_tag AS_TAG
    end

    describe :url_for_direct_upload do
      it "should use the key" do
        key = SecureRandom.base58(24)
        url = @service.url_for_direct_upload(key)
        expect(url).not_to include(BASENAME)
        expect(url).to include("public_id=#{key}")
      end
      it "should include the key in a context field" do
        key = SecureRandom.base58(24)
        url = @service.url_for_direct_upload(key)
        expect(url).to include("context=active_storage_key%3D#{key}")
      end
    end

    it "should support uploading to Cloudinary" do
      url = @service.url_for_direct_upload(key, tags: [TEST_TAG, TIMESTAMP_TAG, AS_TAG])
      uri = URI.parse url
      request = Net::HTTP::Put.new uri.request_uri
      file = File.open(TEST_IMG)
      request.body_stream = file
      request['content-length'] = file.size
      request['content-type'] = 'image/png'
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request request
      end
      result = Cloudinary::Utils.json_decode(response.body)
      expect(result['error']).not_to be_truthy
      #Same test as uploader_spec "should successfully upload file"
      expect(result["width"]).to eq(TEST_IMG_W)
      expect(result["height"]).to eq(TEST_IMG_H)
      expected_signature = Cloudinary::Utils.api_sign_request({:public_id => result["public_id"], :version => result["version"]}, Cloudinary.config.api_secret)
      expect(result["signature"]).to eq(expected_signature)
    end

    it "should check if resource exists" do
      expect(@service.exist?(@key)).to be_truthy
      expect(@service.exist?(@key + "nonsense")).to be_falsey
    end

    it "should delete a resource" do
      @service.delete @key
      expect(@service.exist?(@key)).to be_falsey
    end

    it "should fail to delete nonexistent key" do
      expect {@service.delete SecureRandom.base58(24)}.not_to raise_error
    end

    it "should support transformations" do
      url = @service.url(@key, crop: 'scale', width: 100)
      expect(url).to match(/c_scale,w_100/)
    end

    it "should use global configuration options" do
      tags = SERVICE_CONFIGURATIONS[:cloudinary][:tags]
      expect(tags).not_to be_empty, "Please set a tags value under cloudinary in #{CONFIGURATION_PATH}"
      expect(Cloudinary::Uploader).to receive(:upload).with(TEST_IMG, hash_including(tags: tags))
      @service.upload(key, TEST_IMG, tags: tags)
    end

    it "should accept options that override global configuration" do
      tags = SERVICE_CONFIGURATIONS[:cloudinary][:tags]
      expect(tags).not_to be_empty, "Please set a tags value under cloudinary in #{CONFIGURATION_PATH}"
      override_tags = [TEST_TAG, TIMESTAMP_TAG, AS_TAG]
      expect(override_tags).not_to eql(tags), "Overriding tags should be different from configuration"
      expect(Cloudinary::Uploader).to receive(:upload).with(TEST_IMG, hash_including(tags: override_tags))
      @service.upload(key, TEST_IMG, tags: override_tags)
    end
  end
end
