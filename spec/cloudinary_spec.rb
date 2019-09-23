require 'spec_helper'
require 'cloudinary'

describe Cloudinary do
  before :all do
    @user_platform = Cloudinary.user_platform
  end
  after :all do
    Cloudinary.user_platform = @user_platform
  end

  it 'should add a user platform to USER_AGENT' do
    Cloudinary.user_platform = "Spec/1.0 (Test)"
    expect(Cloudinary.USER_AGENT).to match( %r"Spec\/1.0 \(Test\) CloudinaryRuby/[\d.]+")

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
        valid_cloudinary_url = "cloudinary://key:secret@test123"
        expect{Cloudinary::config_from_url valid_cloudinary_url}.not_to raise_error
    end
    it "should raise an exception if the CLOUDINARY_URL doesn't start with 'cloudinary://'" do
      invalid_cloudinary_urls = [
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        ""
      ]
      invalid_cloudinary_urls.each do |cloudinary_url|
        expect{Cloudinary::config_from_url cloudinary_url}
          .to raise_error(CloudinaryException)
      end
      invalid_cloudinary_urls = [
         "CLOUDINARY_URL=cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
         "://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
         " "
      ]
      invalid_cloudinary_urls.each do |cloudinary_url|
        expect{Cloudinary::config_from_url cloudinary_url}
          .to raise_error(URI::InvalidURIError)
      end
    end
  end
end
