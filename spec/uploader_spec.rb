require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Uploader do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?

  it "should successfully upload file" do
    result = Cloudinary::Uploader.upload("spec/logo.png")    
    result["width"].should == 241
    result["height"].should == 51
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>result["public_id"], :version=>result["version"]}, Cloudinary.config.api_secret)
    result["signature"].should == expected_signature
  end

  it "should successfully upload file by url" do
    result = Cloudinary::Uploader.upload("http://cloudinary.com/images/logo.png")
    result["width"].should == 241
    result["height"].should == 51
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>result["public_id"], :version=>result["version"]}, Cloudinary.config.api_secret)
    result["signature"].should == expected_signature
  end
  
  it "should successfully rename a file" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    Cloudinary::Uploader.rename(result["public_id"], result["public_id"]+"2")
    Cloudinary::Api.resource(result["public_id"]+"2").should_not be_nil

    result2 = Cloudinary::Uploader.upload("spec/favicon.ico")
    lambda{Cloudinary::Uploader.rename(result2["public_id"], result["public_id"]+"2")}.should raise_error
    Cloudinary::Uploader.rename(result2["public_id"], result["public_id"]+"2", :overwrite=>true)

    Cloudinary::Api.resource(result["public_id"]+"2")["format"].should == "ico"
  end

  it "should support explicit" do
    result = Cloudinary::Uploader.explicit("cloudinary", :type=>"twitter_name", :eager=>[{:crop=>"scale", :width=>"2.0"}])
    url = Cloudinary::Utils.cloudinary_url("cloudinary", :type=>"twitter_name", :crop=>"scale", :width=>"2.0", :format=>"png", :version=>result["version"])
    result["eager"][0]["url"].should == url
  end
  
  it "should support eager" do
    Cloudinary::Uploader.upload("spec/logo.png", :eager=>[{:crop=>"scale", :width=>"2.0"}])
  end

  it "should support headers" do
    Cloudinary::Uploader.upload("spec/logo.png", :headers=>["Link: 1"])
    Cloudinary::Uploader.upload("spec/logo.png", :headers=>{"Link" => "1"})
  end

  it "should successfully generate text image" do
    result = Cloudinary::Uploader.text("hello world")
    result["width"].should > 1
    result["height"].should > 1
  end

  it "should correctly handle tags" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    Cloudinary::Uploader.add_tag("tag1", result["public_id"])
    Cloudinary::Uploader.add_tag("tag2", result["public_id"])
    Cloudinary::Api.resource(result["public_id"])["tags"].should == ["tag1", "tag2"]
    Cloudinary::Uploader.remove_tag("tag1", result["public_id"])
    Cloudinary::Api.resource(result["public_id"])["tags"].should == ["tag2"]
    Cloudinary::Uploader.replace_tag("tag3", result["public_id"])
    Cloudinary::Api.resource(result["public_id"])["tags"].should == ["tag3"]
  end  
end
