require "spec_helper"

describe Cloudinary do
  describe ".config" do
    include_context "config"

    it "should allow nested values in CLOUDINARY_URL" do
      ENV["CLOUDINARY_URL"] = "cloudinary://key:secret@test123?foo[bar]=value"
      Cloudinary.config_from_url ENV["CLOUDINARY_URL"]
      expect(Cloudinary.config.foo.bar).to eq "value"
    end

    it "should accept a CLOUDINARY_URL with the correct scheme (cloudinary)" do
      valid_cloudinary_url = "cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
      expect { Cloudinary.config_from_url valid_cloudinary_url }.not_to raise_error
    end

    it "should not be sensitive to case in CLOUDINARY_URL's protocol" do
      valid_cloudinary_url = "CLouDiNaRY://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
      expect { Cloudinary.config_from_url valid_cloudinary_url }.not_to raise_error
    end

    it "should raise an exception if the CLOUDINARY_URL doesn't start with 'cloudinary://'" do
      invalid_cloudinary_urls = [
        "CLOUDINARY_URL=cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test?cloudinary=foo",
        " "
      ]

      invalid_cloudinary_urls.each do |cloudinary_url|
        expect { Cloudinary.config_from_url cloudinary_url }
          .to raise_error(/bad URI|Invalid CLOUDINARY_URL/)
      end
    end

    it "should support CLOUDINARY_ prefixed environment variables that are unrelated to config" do
      ENV["CLOUDINARY_CLOUD_NAME"] = "c"
      ENV["CLOUDINARY_API_KEY"] = "k"
      ENV["CLOUDINARY_API_SECRET"] = "s"
      ENV["CLOUDINARY_SECURE_DISTRIBUTION"] = "sd"
      ENV["CLOUDINARY_PRIVATE_CDN"] = "false"
      ENV["CLOUDINARY_SECURE"] = "true"
      ENV["CLOUDINARY_API_PROXY"] = "https://myuser:mypass@my.proxy.com"

      expect(Cloudinary.config.cloud_name).to eq "c"
      expect(Cloudinary.config.api_key).to eq "k"
      expect(Cloudinary.config.api_secret).to eq "s"
      expect(Cloudinary.config.secure_distribution).to eq "sd"
      expect(Cloudinary.config.private_cdn).to eq false
      expect(Cloudinary.config.secure).to eq true
      expect(Cloudinary.config.api_proxy).to eq "https://myuser:mypass@my.proxy.com"
    end

    it "should accept CLOUDINARY_URL without explicitly setting it" do
      ENV["CLOUDINARY_URL"] = "cloudinary://key:secret@test123"

      expect(Cloudinary.config).to have_cloudinary_config(cloud_name: "test123",
                                                          api_key: "key",
                                                          api_secret: "secret")
    end

    it "should raise an exception if CLOUDINARY_URL contains Cloudinary account url" do
      ENV["CLOUDINARY_URL"] = "account://api-key:api-secret@account-id"

      expect { Cloudinary.config }.to raise_error(/bad URI|Invalid CLOUDINARY_URL/)
    end

    it "should work even if Cloudinary account url is not set" do
      ENV["CLOUDINARY_URL"] = "cloudinary://key:secret@test123?foo[bar]=value"
      ENV.delete("CLOUDINARY_ACCOUNT_URL")

      expect(Cloudinary.account_config.cloud_name).to be_nil
      expect(Cloudinary.config.cloud_name).to eq "test123"
    end
    
    it "overwrites only existing keys from environment" do
      ENV["CLOUDINARY_CLOUD_NAME"] = "c"
      ENV["CLOUDINARY_API_KEY"] = "key_from_env"

      allow(Cloudinary).to receive(:import_settings_from_file) { OpenStruct.new(api_secret: "secret_from_settings") }
      
      expect(Cloudinary.config.cloud_name).to eq "c"
      expect(Cloudinary.config.api_key).to eq "key_from_env"
      expect(Cloudinary.config.api_secret).to eq "secret_from_settings"
    end
  end
end
