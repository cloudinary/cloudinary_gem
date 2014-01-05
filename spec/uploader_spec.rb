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
  
  it "should successfully upload a file from pathname", :pathname => true do
    result = Cloudinary::Uploader.upload(Pathname.new("spec/logo.png"))
    result["width"].should == 241
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
  
  it "should correctly handle unique_filename" do
    result = Cloudinary::Uploader.upload("spec/logo.png", use_filename: true)
    result["public_id"].should match(/logo_[a-zA-Z0-9]{6}/)
    result = Cloudinary::Uploader.upload("spec/logo.png", use_filename: true, unique_filename: false)
    result["public_id"].should  == "logo"
  end
  
  it "should allow whitelisted formats if allowed_formats", :allowed=>true do
    result = Cloudinary::Uploader.upload("spec/logo.png", allowed_formats: ["png"])
    result["format"].should == "png"
  end
  
  it "should prevent non whitelisted formats from being uploaded if allowed_formats is specified", :allowed=>true do
    lambda{Cloudinary::Uploader.upload("spec/logo.png", allowed_formats: ["jpg"])}.should raise_error
  end
  
  it "should allow non whitelisted formats if type is specified and convert to that type", :allowed=>true do
    result = Cloudinary::Uploader.upload("spec/logo.png", allowed_formats: ["jpg"], format: "jpg")
    result["format"].should == "jpg"
  end
  
  it "should allow sending face coordinates" do
    coordinates = [[120, 30, 109, 150], [121, 31, 110, 151]]
    result = Cloudinary::Uploader.upload("spec/logo.png", {face_coordinates: coordinates, faces: true})
    result["faces"].should == coordinates

    different_coordinates = [[122, 32, 111, 152]]
    Cloudinary::Uploader.explicit(result["public_id"], {face_coordinates: different_coordinates, faces: true, type: "upload"})
    info = Cloudinary::Api.resource(result["public_id"], {faces: true})
    info["faces"].should == different_coordinates
  end
  
  it "should allow sending context" do
    context = {"caption" => "some caption", "alt" => "alternative"}
    result = Cloudinary::Uploader.upload("spec/logo.png", {:context => context})
    info = Cloudinary::Api.resource(result["public_id"], {:context => true})
    info["context"].should == {"custom" => context}
  end
end
