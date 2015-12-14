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
end