require 'rspec'
require 'spec_helper'
require 'cloudinary'

KEY     = "00112233FF99"
ALT_KEY = "CCBB2233FF00"

describe 'auth_token' do
  before :all do
    @url_backup = ENV["CLOUDINARY_URL"]
  end
  before do
    Cloudinary.config_from_url "cloudinary://a:b@test123?load_strategies=false"
    Cloudinary.config.auth_token = { :key => KEY, :duration => 300, :start_time => 11111111 }
  end
  after do
    ENV["CLOUDINARY_URL"] = @url_backup
    Cloudinary::config_from_url @url_backup
  end
  it "should generate with start and duration" do
    token = Cloudinary::Utils.generate_auth_token :start_time => 1111111111, :acl => "/image/*", :duration => 300
    expect(token).to eq '__cld_token__=st=1111111111~exp=1111111411~acl=/image/*~hmac=0854e8b6b6a46471a80b2dc28c69bd352d977a67d031755cc6f3486c121b43af'
  end

  describe "authenticated url" do
    before do
      Cloudinary.config :private_cdn => true

    end
    it "should add token if authToken is globally set and signed = true" do
      url = Cloudinary::Utils.cloudinary_url "sample.jpg", :sign_url => true, :resource_type => "image", :type => "authenticated", :version => "1486020273"
      expect(url).to eq("http://test123-res.cloudinary.com/image/authenticated/v1486020273/sample.jpg?__cld_token__=st=11111111~exp=11111411~hmac=8db0d753ee7bbb9e2eaf8698ca3797436ba4c20e31f44527e43b6a6e995cfdb3")

    end
    it "should add token for 'public' resource" do
      url = Cloudinary::Utils.cloudinary_url "sample.jpg", :sign_url => true, :resource_type => "image", :type => "public", :version => "1486020273"
      expect(url).to eq("http://test123-res.cloudinary.com/image/public/v1486020273/sample.jpg?__cld_token__=st=11111111~exp=11111411~hmac=c2b77d9f81be6d89b5d0ebc67b671557e88a40bcf03dd4a6997ff4b994ceb80e")

    end
    it "should not add token if signed is false" do
      url = Cloudinary::Utils.cloudinary_url "sample.jpg", :type => "authenticated", :version => "1486020273"
      expect(url).to eq("http://test123-res.cloudinary.com/image/authenticated/v1486020273/sample.jpg")

    end
    it "should not add token if authToken is globally set but null auth token is explicitly set and signed = true" do
      url = Cloudinary::Utils.cloudinary_url "sample.jpg", :auth_token => false, :sign_url => true, :type => "authenticated", :version => "1486020273"
      expect(url).to eq("http://test123-res.cloudinary.com/image/authenticated/s--v2fTPYTu--/v1486020273/sample.jpg")

    end
    it "explicit authToken should override global setting" do
      url = Cloudinary::Utils.cloudinary_url "sample.jpg", :sign_url => true, :auth_token => { :key => ALT_KEY, :start_time => 222222222, :duration => 100 }, :type => "authenticated", :transformation => { :crop => "scale", :width => 300 }
      expect(url).to eq("http://test123-res.cloudinary.com/image/authenticated/c_scale,w_300/sample.jpg?__cld_token__=st=222222222~exp=222222322~hmac=7d276841d70c4ecbd0708275cd6a82e1f08e47838fbb0bceb2538e06ddfa3029")

    end
    it "should compute expiration as start time + duration" do
      token = { :key => KEY, :start_time => 11111111, :duration => 300 }
      url   = Cloudinary::Utils.cloudinary_url "sample.jpg", :sign_url => true, :auth_token => token, :resource_type => "image", :type => "authenticated", :version => "1486020273"
      expect(url).to eq("http://test123-res.cloudinary.com/image/authenticated/v1486020273/sample.jpg?__cld_token__=st=11111111~exp=11111411~hmac=8db0d753ee7bbb9e2eaf8698ca3797436ba4c20e31f44527e43b6a6e995cfdb3")

    end
  end
  describe "authentication token" do
    it "should generate token string" do
      user                      = "foobar" # we can't rely on the default "now" value in tests
      tokenOptions              = { :key => KEY, :duration => 300, :acl => "/*/t_#{user}" }
      tokenOptions[:start_time] = 222222222 # we can't rely on the default "now" value in tests
      cookieToken               = Cloudinary::Utils.generate_auth_token tokenOptions
      expect(cookieToken).to eq("__cld_token__=st=222222222~exp=222222522~acl=/*/t_foobar~hmac=eb5e2266c8ec9573f696025f075b92998080347e1c12ac39a26c94d7d712704a")

    end
  end
end

