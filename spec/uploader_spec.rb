require 'spec_helper'
require 'cloudinary'

RSpec.configure do |c|
  c.filter_run_excluding :large => true
end

describe Cloudinary::Uploader do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?

  it "should successfully upload file" do
    result = Cloudinary::Uploader.upload("spec/logo.png")    
    expect(result["width"]).to eq(241)
    expect(result["height"]).to eq(51)
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>result["public_id"], :version=>result["version"]}, Cloudinary.config.api_secret)
    expect(result["signature"]).to eq(expected_signature)
  end
  
  it "should successfully upload a file from pathname", :pathname => true do
    result = Cloudinary::Uploader.upload(Pathname.new("spec/logo.png"))
    expect(result["width"]).to eq(241)
  end

  it "should successfully upload file by url" do
    result = Cloudinary::Uploader.upload("http://cloudinary.com/images/old_logo.png")
    expect(result["width"]).to eq(241)
    expect(result["height"]).to eq(51)
    expected_signature = Cloudinary::Utils.api_sign_request({:public_id=>result["public_id"], :version=>result["version"]}, Cloudinary.config.api_secret)
    expect(result["signature"]).to eq(expected_signature)
  end
  
  it "should successfully rename a file" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    Cloudinary::Uploader.rename(result["public_id"], result["public_id"]+"2")
    expect(Cloudinary::Api.resource(result["public_id"]+"2")).not_to be_nil

    result2 = Cloudinary::Uploader.upload("spec/favicon.ico")
    expect{Cloudinary::Uploader.rename(result2["public_id"], result["public_id"]+"2")}.to raise_error
    Cloudinary::Uploader.rename(result2["public_id"], result["public_id"]+"2", :overwrite=>true)

    expect(Cloudinary::Api.resource(result["public_id"]+"2")["format"]).to eq("ico")
  end

  it "should support explicit" do
    result = Cloudinary::Uploader.explicit("cloudinary", :type=>"twitter_name", :eager=>[{:crop=>"scale", :width=>"2.0"}])
    url = Cloudinary::Utils.cloudinary_url("cloudinary", :type=>"twitter_name", :crop=>"scale", :width=>"2.0", :format=>"png", :version=>result["version"])
    expect(result["eager"][0]["url"]).to eq(url)
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
    expect(result["width"]).to be > 1
    expect(result["height"]).to be > 1
  end

  it "should correctly handle tags" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    Cloudinary::Uploader.add_tag("tag1", result["public_id"])
    Cloudinary::Uploader.add_tag("tag2", result["public_id"])
    expect(Cloudinary::Api.resource(result["public_id"])["tags"]).to eq(["tag1", "tag2"])
    Cloudinary::Uploader.remove_tag("tag1", result["public_id"])
    expect(Cloudinary::Api.resource(result["public_id"])["tags"]).to eq(["tag2"])
    Cloudinary::Uploader.replace_tag("tag3", result["public_id"])
    expect(Cloudinary::Api.resource(result["public_id"])["tags"]).to eq(["tag3"])
  end
  
  it "should correctly handle unique_filename" do
    result = Cloudinary::Uploader.upload("spec/logo.png", :use_filename => true)
    expect(result["public_id"]).to match(/logo_[a-zA-Z0-9]{6}/)
    result = Cloudinary::Uploader.upload("spec/logo.png", :use_filename => true, :unique_filename => false)
    expect(result["public_id"]).to eq("logo")
  end
  
  it "should allow whitelisted formats if allowed_formats", :allowed=>true do
    result = Cloudinary::Uploader.upload("spec/logo.png", :allowed_formats => ["png"])
    expect(result["format"]).to eq("png")
  end
  
  it "should prevent non whitelisted formats from being uploaded if allowed_formats is specified", :allowed=>true do
    expect{Cloudinary::Uploader.upload("spec/logo.png", :allowed_formats => ["jpg"])}.to raise_error
  end
  
  it "should allow non whitelisted formats if type is specified and convert to that type", :allowed=>true do
    result = Cloudinary::Uploader.upload("spec/logo.png", :allowed_formats => ["jpg"], :format => "jpg")
    expect(result["format"]).to eq("jpg")
  end
  
  it "should allow sending face coordinates" do
    coordinates = [[120, 30, 109, 150], [121, 31, 110, 151]]
    result = Cloudinary::Uploader.upload("spec/logo.png", {:face_coordinates => coordinates, :faces => true})
    expect(result["faces"]).to eq(coordinates)

    different_coordinates = [[122, 32, 111, 152]]
    Cloudinary::Uploader.explicit(result["public_id"], {:face_coordinates => different_coordinates, :faces => true, :type => "upload"})
    info = Cloudinary::Api.resource(result["public_id"], {:faces => true})
    expect(info["faces"]).to eq(different_coordinates)
  end
  
  it "should allow sending context" do
    context = {"caption" => "some caption", "alt" => "alternative"}
    result = Cloudinary::Uploader.upload("spec/logo.png", {:context => context})
    info = Cloudinary::Api.resource(result["public_id"], {:context => true})
    expect(info["context"]).to eq({"custom" => context})
  end
  
  it "should support requesting manual moderation" do
    result = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    expect(result["moderation"][0]["status"]).to eq("pending")
    expect(result["moderation"][0]["kind"]).to eq("manual")
  end
    
  it "should support requesting raw conversion" do
    expect{Cloudinary::Uploader.upload("spec/docx.docx", {:resource_type => :raw, :raw_convert => :illegal})}.to raise_error(CloudinaryException, /Illegal value|not a valid/)
  end
  
  it "should support requesting categorization" do
    expect{Cloudinary::Uploader.upload("spec/logo.png", {:categorization => :illegal})}.to raise_error(CloudinaryException, /Illegal value|not a valid/)
  end
  
  it "should support requesting detection" do
    expect{Cloudinary::Uploader.upload("spec/logo.png", {:detection => :illegal})}.to raise_error(CloudinaryException, /Illegal value|not a valid/)
  end
  
  it "should support requesting auto_tagging" do
    expect{Cloudinary::Uploader.upload("spec/logo.png", {:auto_tagging => 0.5})}.to raise_error(CloudinaryException, /Must use/)
  end

  it "should support upload_large", :large => true do
    io = StringIO.new
    header = "BMJ\xB9Y\x00\x00\x00\x00\x00\x8A\x00\x00\x00|\x00\x00\x00x\x05\x00\x00x\x05\x00\x00\x01\x00\x18\x00\x00\x00\x00\x00\xC0\xB8Y\x00a\x0F\x00\x00a\x0F\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\x00\x00\xFF\x00\x00\xFF\x00\x00\x00\x00\x00\x00\xFFBGRs\x00\x00\x00\x00\x00\x00\x00\x00T\xB8\x1E\xFC\x00\x00\x00\x00\x00\x00\x00\x00fff\xFC\x00\x00\x00\x00\x00\x00\x00\x00\xC4\xF5(\xFF\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
    io.puts(header)
    5880000.times{ io.write("\xFF") }
    io.rewind
    result = Cloudinary::Uploader.upload_large(io, :chunk_size => 5243000)
    expect(result["resource_type"]).to eq('raw')
    io.rewind
    result = Cloudinary::Uploader.upload_large(io, :resource_type => 'image', :chunk_size => 5243000)
    expect(result["resource_type"]).to eq('image')
    expect(result["width"]).to eq(1400)
    expect(result["height"]).to eq(1400)
    expect(result["format"]).to eq("bmp")
  end
  
  context "unsigned" do
    after do
      Cloudinary.class_variable_set(:@@config, nil)
    end
    
    it "should support unsigned uploading using presets", :upload_preset => true do
      preset = Cloudinary::Api.create_upload_preset(:folder => "test_folder_upload", :unsigned => true)

      Cloudinary.config.api_key = nil
      Cloudinary.config.api_secret = nil

      result = Cloudinary::Uploader.unsigned_upload("spec/logo.png", preset["name"])
      expect(result["public_id"]).to match(/^test_folder_upload\/[a-z0-9]+$/)

      Cloudinary.class_variable_set(:@@config, nil)

      Cloudinary::Api.delete_upload_preset(preset["name"])
    end
  end

  describe ":timeout" do
    before do
      @timeout = Cloudinary.config.timeout
      Cloudinary.config.timeout = 0.01
    end
    after do
      Cloudinary.config.timeout = @timeout
    end

    it "should fail if timeout is reached" do
      expect{Cloudinary::Uploader.upload(Pathname.new("spec/logo.png"))}.to raise_error
    end
  end
end
