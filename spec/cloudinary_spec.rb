require 'spec_helper'
require 'cloudinary'

describe Cloudinary do
  before :each do
    @user_platform = Cloudinary.user_platform
  end
  after :each do
    Cloudinary.user_platform = @user_platform
  end

  CLOUDINARY_USER_AGENT_REGEXP    = %r"^CloudinaryRuby\/[\d.]+ \(Ruby [\d\.]+-p\d+\)$"
  CLOUDINARY_USER_PLATFORM_REGEXP = %r"^Rails\/[\d.]+ CloudinaryRuby\/[\d.]+ \(Ruby [\d\.]+-p\d+\)$"

  it "should return the USER_AGENT without user_platform if there's no Rails or set to empty" do
    Cloudinary.user_platform = ""
    expect(Cloudinary.USER_AGENT).to match(CLOUDINARY_USER_AGENT_REGEXP)
  end

  it 'should add a user platform to USER_AGENT' do
    Cloudinary.user_platform = "Rails/5.6.7"
    expect(Cloudinary.USER_AGENT).to match(CLOUDINARY_USER_PLATFORM_REGEXP)
  end

  describe 'config' do
    before do
      @url_backup = ENV["CLOUDINARY_URL"]
    end
    after do
      ENV.keys.select! { |key| key.start_with? "CLOUDINARY_" }.each { |key| ENV.delete(key) }
      ENV["CLOUDINARY_URL"] = @url_backup
      Cloudinary::config_from_url @url_backup
    end
    it "should allow nested values in CLOUDINARY_URL" do
      ENV["CLOUDINARY_URL"]  = "cloudinary://key:secret@test123?foo[bar]=value"
      Cloudinary::config_from_url ENV["CLOUDINARY_URL"]
      expect(Cloudinary::config.foo.bar).to eq 'value'
    end

    it "should set accept a CLOUDINARY_URL with the correct scheme (cloudinary)" do
        valid_cloudinary_url = "cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
        expect{Cloudinary::config_from_url valid_cloudinary_url}.not_to raise_error
    end
    it "should raise an exception if the CLOUDINARY_URL doesn't start with 'cloudinary://'" do
      invalid_cloudinary_urls = [
        "CLOUDINARY_URL=cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        " "
      ]
      invalid_cloudinary_urls.each do |cloudinary_url|
        expect{Cloudinary::config_from_url cloudinary_url}
          .to raise_error(/bad URI|Invalid CLOUDINARY_URL/)
      end
    end

    it "should support CLOUDINARY_ prefixed environment variables" do
      Cloudinary.reset_config

      ENV["CLOUDINARY_CLOUD_NAME"] = "c"
      ENV["CLOUDINARY_API_KEY"] = "k"
      ENV["CLOUDINARY_API_SECRET"] = "s"
      ENV["CLOUDINARY_SECURE_DISTRIBUTION"] = "sd"
      ENV["CLOUDINARY_PRIVATE_CDN"] = "false"
      ENV["CLOUDINARY_SECURE"] = "true"
      ENV["CLOUDINARY_API_PROXY"] = "https://myuser:mypass@my.proxy.com"

      expect(Cloudinary::config.cloud_name).to eq "c"
      expect(Cloudinary::config.api_key).to eq "k"
      expect(Cloudinary::config.api_secret).to eq "s"
      expect(Cloudinary::config.secure_distribution).to eq "sd"
      expect(Cloudinary::config.private_cdn).to eq false
      expect(Cloudinary::config.secure).to eq true
      expect(Cloudinary::config.api_proxy).to eq "https://myuser:mypass@my.proxy.com"
    end
  end
end
