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
end
