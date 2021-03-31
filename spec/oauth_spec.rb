require "spec_helper"
require "cloudinary"

describe "OAuth" do
  include_context "cleanup"

  FAKE_OAUTH_TOKEN = "MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI4"

  let(:unique_image_public_id) { "asset_image_#{UNIQUE_TEST_ID}" }

  before do
    Cloudinary::Uploader.upload(TEST_IMG, :public_id => unique_image_public_id, :tags => [TEST_TAG, TIMESTAMP_TAG])
  end

  after do
    Cloudinary.reset_config
  end

  it "validates oauth token" do
    Cloudinary::config.oauth_token = FAKE_OAUTH_TOKEN

    expect { Cloudinary::Api.resource(unique_image_public_id) }.to raise_error(/Invalid token/)
  end
end
