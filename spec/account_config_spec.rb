require "spec_helper"
require "cloudinary"

describe Cloudinary do
  describe ".account_config" do
    before do
      Cloudinary.reset_config
      @cloudinary_url_backup = ENV["CLOUDINARY_URL"]
      @account_url_backup = ENV["CLOUDINARY_ACCOUNT_URL"]
    end

    after do
      ENV.keys.select { |key| key.start_with? "CLOUDINARY_" }.each { |key| ENV.delete(key) }
      ENV["CLOUDINARY_ACCOUNT_URL"] = @url_backup
      ENV['CLOUDINARY_URL'] = @cloudinary_url_backup
      Cloudinary.reset_config
    end

    it "should allow nested values in CLOUDINARY_ACCOUNT_URL" do
      ENV["CLOUDINARY_ACCOUNT_URL"]  = "account://key:secret@test123?foo[bar]=value"
      Cloudinary.config_from_account_url ENV["CLOUDINARY_ACCOUNT_URL"]
      expect(Cloudinary.account_config.foo.bar).to eq "value"
    end

    it "should set accept a CLOUDINARY_ACCOUNT_URL with the correct scheme (account)" do
      valid_account_url = "account://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
      expect { Cloudinary.config_from_account_url valid_account_url }.not_to raise_error
    end

    it "should raise an exception if the CLOUDINARY_ACCOUNT_URL doesn't start with 'account://'" do
      invalid_account_urls = [
        "cloudinary://api-key:api-secret@account-id",
        "CLOUDINARY_ACCOUNT_URL=cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        " "
      ]

      invalid_account_urls.each do |cloudinary_url|
        expect { Cloudinary.config_from_account_url cloudinary_url }
          .to raise_error(/bad URI|Invalid CLOUDINARY_ACCOUNT_URL/)
      end
    end

    it "should not support CLOUDINARY_ prefixed environment variables" do
      ENV["CLOUDINARY_CLOUD_NAME"] = "c"
      ENV["CLOUDINARY_API_KEY"] = "k"
      ENV["CLOUDINARY_API_SECRET"] = "s"
      ENV["CLOUDINARY_SECURE_DISTRIBUTION"] = "sd"
      ENV["CLOUDINARY_PRIVATE_CDN"] = "false"
      ENV["CLOUDINARY_SECURE"] = "true"

      expect(Cloudinary.account_config.cloud_name).to be_nil
      expect(Cloudinary.account_config.api_key).to be_nil
      expect(Cloudinary.account_config.api_secret).to be_nil
      expect(Cloudinary.account_config.secure_distribution).to be_nil
      expect(Cloudinary.account_config.private_cdn).to be_nil
      expect(Cloudinary.account_config.secure).to be_nil
    end

    it "should accept both CLOUDINARY_URL and CLOUDINARY_ACCOUNT_URL" do
      valid_account_url = "account://api-key:api-secret@account-id"
      valid_cloudinary_url = "cloudinary://key:secret@test123"

      Cloudinary.config_from_account_url valid_account_url
      Cloudinary.config_from_url valid_cloudinary_url

      expect(Cloudinary.config).to have_cloudinary_config(cloud_name: "test123",
                                                          api_key: "key",
                                                          api_secret: "secret")

      expect(Cloudinary.account_config).to have_cloudinary_account_config(account_id: "account-id",
                                                                          provisioning_api_key: "api-key",
                                                                          provisioning_api_secret: "api-secret")
    end

    it "should accept both CLOUDINARY_URL and CLOUDINARY_ACCOUNT_URL without explicitly setting them" do
      ENV["CLOUDINARY_ACCOUNT_URL"] = "account://api-key:api-secret@account-id"
      ENV["CLOUDINARY_URL"] = "cloudinary://key:secret@test123"

      expect(Cloudinary.config).to have_cloudinary_config(cloud_name: "test123",
                                                          api_key: "key",
                                                          api_secret: "secret")

      expect(Cloudinary.account_config).to have_cloudinary_account_config(account_id: "account-id",
                                                                          provisioning_api_key: "api-key",
                                                                          provisioning_api_secret: "api-secret")
    end

    it "should raise an exception if CLOUDINARY_ACCOUNT_URL contains cloudinary url" do
      ENV["CLOUDINARY_ACCOUNT_URL"] = "cloudinary://key:secret@test123"

      expect { Cloudinary.account_config }.to raise_error(/bad URI|Invalid CLOUDINARY_ACCOUNT_URL/)
    end

    it "should raise an exception if CLOUDINARY_URL contains cloudinary account url" do
      ENV["CLOUDINARY_URL"] = "account://api-key:api-secret@account-id"

      expect { Cloudinary.config }.to raise_error(/bad URI|Invalid CLOUDINARY_URL/)
    end
  end
end
