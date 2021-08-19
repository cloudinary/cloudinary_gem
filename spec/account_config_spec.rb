require "spec_helper"
require "cloudinary"

describe Cloudinary do
  describe ".account_config" do
    include_context "config"

    it "should allow nested values in CLOUDINARY_ACCOUNT_URL" do
      ENV["CLOUDINARY_ACCOUNT_URL"]  = "account://key:secret@test123?foo[bar]=value"
      Cloudinary.config_from_account_url ENV["CLOUDINARY_ACCOUNT_URL"]
      expect(Cloudinary.account_config.foo.bar).to eq "value"
    end

    it "should accept a CLOUDINARY_ACCOUNT_URL with the correct scheme (account)" do
      valid_account_url = "account://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
      expect { Cloudinary.config_from_account_url valid_account_url }.not_to raise_error
    end

    it "should not be sensitive to case in CLOUDINARY_ACCOUNT_URL's protocol" do
      valid_account_url = "aCCouNT://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test"
      expect { Cloudinary.config_from_account_url valid_account_url }.not_to raise_error
    end

    it "should raise an exception if the CLOUDINARY_ACCOUNT_URL doesn't start with 'account://'" do
      invalid_account_urls = [
        "cloudinary://api-key:api-secret@account-id",
        "CLOUDINARY_ACCOUNT_URL=cloudinary://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test",
        "https://123456789012345:ALKJdjklLJAjhkKJ45hBK92baj3@test?cloudinary=foo",
        " "
      ]

      invalid_account_urls.each do |cloudinary_url|
        expect { Cloudinary.config_from_account_url cloudinary_url }
          .to raise_error(/bad URI|Invalid CLOUDINARY_ACCOUNT_URL/)
      end
    end

    it "should not support CLOUDINARY_ prefixed environment variables that are unrelated to account config" do
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

    it "should set values when both CLOUDINARY_URL and CLOUDINARY_ACCOUNT_URL are set" do
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

    it "should accept CLOUDINARY_ACCOUNT_URL without explicitly setting it" do
      ENV["CLOUDINARY_ACCOUNT_URL"] = "account://api-key:api-secret@account-id"

      expect(Cloudinary.account_config).to have_cloudinary_account_config(account_id: "account-id",
                                                                          provisioning_api_key: "api-key",
                                                                          provisioning_api_secret: "api-secret")
    end

    it "should raise an exception if CLOUDINARY_ACCOUNT_URL contains Cloudinary url" do
      ENV["CLOUDINARY_ACCOUNT_URL"] = "cloudinary://key:secret@test123"

      expect { Cloudinary.account_config }.to raise_error(/bad URI|Invalid CLOUDINARY_ACCOUNT_URL/)
    end

    it "should work even if Cloudinary url is not set" do
      ENV.delete("CLOUDINARY_URL")
      ENV["CLOUDINARY_ACCOUNT_URL"] = "account://api-key:api-secret@account-id"

      expect(Cloudinary.account_config.account_id).to eq("account-id")
      expect(Cloudinary.config.cloud_name).to be_nil
    end
  end
end
