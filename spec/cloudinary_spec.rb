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
  end
end
