require "spec_helper"

describe "Api Authorization" do
  before :all do
    @mock_api = MockedApi
  end
  before do
    Cloudinary::config.cloud_name = DUMMY_CLOUD
    Cloudinary::config.api_key = API_KEY
    Cloudinary::config.api_secret = API_SECRET
  end

  after { Cloudinary::reset_config }

  it "tests oauth_token admin api" do
    Cloudinary::config.oauth_token = OAUTH_TOKEN

    res = @mock_api.ping

    expect(res["headers"]["Authorization"]).not_to be_nil
    expect(res["headers"]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
  end

  it "tests oauth token as an option admin api" do
    res = @mock_api.ping(:oauth_token => OAUTH_TOKEN)

    expect(res["headers"]["Authorization"]).not_to be_nil
    expect(res["headers"]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
  end

  it "tests key and secret admin api" do
    res = @mock_api.ping
    expect(res["headers"]["Authorization"]).not_to be_nil
    expect(res["headers"]["Authorization"]).to eq("Basic a2V5OnNlY3JldA==")
  end

  it "tests missing credentials admin api" do
    Cloudinary::config.oauth_token = nil
    Cloudinary::config.api_key = nil
    Cloudinary::config.api_secret = nil

    expect { Cloudinary::Api.ping }.to raise_error(/Must supply api_key/)
  end

  it "tests oauth token upload api" do
    Cloudinary::config.oauth_token = OAUTH_TOKEN

    res = MockedUploader.upload(TEST_IMG)

    expect(res["headers"]["Authorization"]).not_to be_nil
    expect(res["headers"]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
    expect(res["headers"]["signature"]).to be_nil
  end

  it "tests oauth token as an option upload api" do
    res = MockedUploader.upload(TEST_IMG, :oauth_token => OAUTH_TOKEN)

    expect(res["headers"]["Authorization"]).not_to be_nil
    expect(res["headers"]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
  end

  it "tests key and secret upload api" do
    res = MockedUploader.upload(TEST_IMG)

    expect(res["headers"]["Authorization"]).to be_nil
    expect(res["payload"]["signature"]).not_to be_nil
    expect(res["payload"]["api_key"]).not_to be_nil
  end

  it "tests missing credentials upload api" do
    Cloudinary::config.oauth_token = nil
    Cloudinary::config.api_key = nil
    Cloudinary::config.api_secret = nil

    expect { Cloudinary::Uploader.upload(TEST_IMG) }.to raise_error(/Must supply api_key/)

    # no credentials required for unsigned upload
    res = MockedUploader.unsigned_upload(TEST_IMG, API_TEST_PRESET)

    expect(res["payload"]["upload_preset"]).not_to be_nil
  end
end
