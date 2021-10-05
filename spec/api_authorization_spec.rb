require "spec_helper"

describe "Api Authorization" do
  before do
    Cloudinary::config.cloud_name = DUMMY_CLOUD
    Cloudinary::config.api_key = API_KEY
    Cloudinary::config.api_secret = API_SECRET
  end

  after { Cloudinary::reset_config }

  it "tests oauth_token admin api" do
    Cloudinary::config.oauth_token = OAUTH_TOKEN

    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).not_to be_nil
      expect(options[:headers]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
    end

    Cloudinary::Api.ping
  end

  it "tests oauth token as an option admin api" do
    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).not_to be_nil
      expect(options[:headers]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
    end

    Cloudinary::Api.ping(:oauth_token => OAUTH_TOKEN)
  end

  it "tests key and secret admin api" do
    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).not_to be_nil
      expect(options[:headers]["Authorization"]).to eq("Basic a2V5OnNlY3JldA==")
    end

    Cloudinary::Api.ping
  end

  it "tests missing credentials admin api" do
    Cloudinary::config.oauth_token = nil
    Cloudinary::config.api_key = nil
    Cloudinary::config.api_secret = nil

    expect { Cloudinary::Api.ping }.to raise_error(/Must supply api_key/)
  end

  it "tests oauth token upload api" do
    Cloudinary::config.oauth_token = OAUTH_TOKEN

    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).not_to be_nil
      expect(options[:headers]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
      expect(options[:payload][:signature]).to be_nil
    end

    Cloudinary::Uploader.upload(TEST_IMG)
  end

  it "tests oauth token as an option upload api" do
    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).not_to be_nil
      expect(options[:headers]["Authorization"]).to eq("Bearer #{OAUTH_TOKEN}")
    end

    Cloudinary::Uploader.upload(TEST_IMG, :oauth_token => OAUTH_TOKEN)
  end

  it "tests key and secret upload api" do
    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:headers]["Authorization"]).to be_nil
      expect(options[:payload][:signature]).not_to be_nil
      expect(options[:payload][:api_key]).not_to be_nil
    end

    Cloudinary::Uploader.upload(TEST_IMG)
  end

  it "tests missing credentials upload api" do
    Cloudinary::config.oauth_token = nil
    Cloudinary::config.api_key = nil
    Cloudinary::config.api_secret = nil

    expect { Cloudinary::Uploader.upload(TEST_IMG) }.to raise_error(/Must supply api_key/)

    expect(RestClient::Request).to receive(:execute) do |options|
      expect(options[:payload][:upload_preset]).not_to be_nil
    end

    # no credentials required for unsigned upload
    Cloudinary::Uploader.unsigned_upload(TEST_IMG, API_TEST_PRESET)
  end
end
