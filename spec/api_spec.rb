require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Api do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?

  before(:all) do
    @timestamp_tag = "api_test_tag_#{Time.now.to_i}"
    @api = Cloudinary::Api
    Cloudinary::Uploader.destroy("api_test")
    Cloudinary::Uploader.destroy("api_test2")
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test", :tags=> ["api_test_tag", @timestamp_tag], :context => "key=value", :eager=>[:width=>100,:crop=>:scale])
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test2", :tags=> ["api_test_tag", @timestamp_tag], :context => "key=value", :eager=>[:width=>100,:crop=>:scale])
    @api.delete_transformation("api_test_transformation") rescue nil
    @api.delete_transformation("api_test_transformation2") rescue nil
    @api.delete_transformation("api_test_transformation3") rescue nil
    @api.delete_upload_preset("api_test_upload_preset") rescue nil
    @api.delete_upload_preset("api_test_upload_preset2") rescue nil
    @api.delete_upload_preset("api_test_upload_preset3") rescue nil
    @api.delete_upload_preset("api_test_upload_preset4") rescue nil
  end
  
  it "should allow listing resource_types" do
    expect(@api.resource_types()["resource_types"]).to include("image")
  end

  it "should allow listing resources" do
    resource = @api.resources()["resources"].find{|resource| resource["public_id"] == "api_test"}
    expect(resource).not_to be_blank
    expect(resource["type"]).to eq("upload")
  end

  it "should allow listing resources with cursor" do
    result = @api.resources(:max_results=>1)
    expect(result["resources"]).not_to be_blank
    expect(result["resources"].length).to eq(1)
    expect(result["next_cursor"]).not_to be_blank
    result2 = @api.resources(:max_results=>1, :next_cursor=>result["next_cursor"])
    expect(result2["resources"]).not_to be_blank
    expect(result2["resources"].length).to eq(1)
    expect(result2["resources"][0]["public_id"]).not_to eq(result["resources"][0]["public_id"] )
  end


  it "should allow listing resources by type" do
    resource = @api.resources(:type=>"upload", :tags=>true)["resources"].find{|resource| resource["public_id"] == "api_test"}
    expect(resource).not_to be_blank
    expect(resource["tags"]).to eq(["api_test_tag", @timestamp_tag])
  end

  it "should allow listing resources by prefix" do
    resources = @api.resources(:type=>"upload", :prefix=>"api_test", :tags => true, :context => true)["resources"]
    expect(resources.map{|resource| resource["public_id"]}).to include("api_test", "api_test2")
    expect(resources.map{|resource| resource["tags"]}).to include(["api_test_tag", @timestamp_tag])
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end

  it "should allow listing resources by tag" do
    resources = @api.resources_by_tag("api_test_tag", :tags => true, :context => true)["resources"]
    expect(resources.find{|resource| resource["public_id"] == "api_test"}).not_to be_blank
    expect(resources.map{|resource| resource["tags"]}).to include(["api_test_tag", @timestamp_tag])
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end
  
  it "should allow listing resources by public ids" do
    resources = @api.resources_by_ids(["api_test", "api_test2"], :tags => true, :context => true)["resources"]
    expect(resources.length).to eq(2)
    expect(resources.find{|resource| resource["public_id"] == "api_test"}).not_to be_blank
    expect(resources.map{|resource| resource["tags"]}).to include(["api_test_tag", @timestamp_tag])
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end
  
  it "should allow listing resources by start date", :start_at => true do
    sleep(2)
    start_at = Time.now.to_s
    sleep(2)
    response = Cloudinary::Uploader.upload("spec/logo.png")
    resources = @api.resources(:type=>"upload", :start_at=>start_at, :direction => "asc")["resources"]
    expect(resources.map{|resource| resource["public_id"]}) == [response["public_id"]]
  end
  
  it "should allow listing resources in both directions" do
    asc_resources = @api.resources_by_tag(@timestamp_tag, :type=>"upload", :direction => "asc")["resources"]
    desc_resources = @api.resources_by_tag(@timestamp_tag, :type=>"upload", :direction => "desc")["resources"]
    # NOTE: this assumes the full list fits in a page which is the case unless resources with 'api_test' prefix were
    # uploaded to the account against which this test runs
    expect(asc_resources.reverse).to eq(desc_resources)
    asc_resources_alt = @api.resources_by_tag(@timestamp_tag, :type=>"upload", :direction => 1)["resources"]
    desc_resources_alt = @api.resources_by_tag(@timestamp_tag, :type=>"upload", :direction => -1)["resources"]
    expect(asc_resources_alt.reverse).to eq(desc_resources_alt)
    expect(asc_resources).to eq(asc_resources_alt)
    expect{@api.resources_by_tag(@timestamp_tag, :type=>"upload", :direction => "anythingelse")["resources"]}.to raise_error(Cloudinary::Api::BadRequest)
  end

  it "should allow get resource metadata" do
    resource = @api.resource("api_test")
    expect(resource).not_to be_blank
    expect(resource["public_id"]).to eq("api_test")
    expect(resource["bytes"]).to eq(3381)
    expect(resource["derived"].length).to eq(1)
  end
  
  it "should allow deleting derived resource" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test3", :eager=>[:width=>101,:crop=>:scale])
    resource = @api.resource("api_test3")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(1)
    derived_resource_id = resource["derived"][0]["id"]
    @api.delete_derived_resources(derived_resource_id)
    resource = @api.resource("api_test3")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(0)
  end

  it "should allow deleting resources" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test3")
    resource = @api.resource("api_test3")
    expect(resource).not_to be_blank
    @api.delete_resources(["apit_test", "api_test2", "api_test3"])
    expect{@api.resource("api_test3")}.to raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow deleting resources by prefix" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test_by_prefix")
    resource = @api.resource("api_test_by_prefix")
    expect(resource).not_to be_blank
    @api.delete_resources_by_prefix("api_test_by")
    expect{@api.resource("api_test_by_prefix")}.to raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow deleting resources by tags" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test4", :tags=>["api_test_tag_for_delete"])
    resource = @api.resource("api_test4")
    expect(resource).not_to be_blank
    @api.delete_resources_by_tag("api_test_tag_for_delete")
    expect{@api.resource("api_test4")}.to raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow listing tags" do
    tags = @api.tags()["tags"]
    expect(tags).to include('api_test_tag')
  end

  it "should allow listing tag by prefix" do
    tags = @api.tags(:prefix=>"api_test")["tags"]
    expect(tags).to include('api_test_tag')
    tags = @api.tags(:prefix=>"api_test_no_such_tag")["tags"]
    expect(tags).to be_blank
  end
  
  it "should allow listing transformations" do
    transformation = @api.transformations()["transformations"].find{|transformation| transformation["name"] == "c_scale,w_100"}
    expect(transformation).not_to be_blank
    expect(transformation["used"]).to eq(true)
  end

  it "should allow getting transformation metadata" do
    transformation = @api.transformation("c_scale,w_100")
    expect(transformation).not_to be_blank  
    expect(transformation["info"]).to eq(["crop"=>"scale", "width"=>100]     )
    transformation = @api.transformation("crop"=>"scale", "width"=>100)
    expect(transformation).not_to be_blank  
    expect(transformation["info"]).to eq(["crop"=>"scale", "width"=>100]     )
  end
  
  it "should allow updating transformation allowed_for_strict" do
    @api.update_transformation("c_scale,w_100", :allowed_for_strict=>true)
    transformation = @api.transformation("c_scale,w_100")
    expect(transformation).not_to be_blank  
    expect(transformation["allowed_for_strict"]).to eq(true)
    @api.update_transformation("c_scale,w_100", :allowed_for_strict=>false)
    transformation = @api.transformation("c_scale,w_100")
    expect(transformation).not_to be_blank  
    expect(transformation["allowed_for_strict"]).to eq(false)
  end
  describe "named transformations" do
    it "should allow creating named transformation" do
      @api.create_transformation("api_test_transformation", "crop"=>"scale", "width"=>102)
      transformation = @api.transformation("api_test_transformation")
      expect(transformation).not_to be_blank
      expect(transformation["allowed_for_strict"]).to eq(true)
      expect(transformation["info"]).to eq(["crop"=>"scale", "width"=>102])
      expect(transformation["used"]).to eq(false)
    end

    it "should allow deleting named transformation" do
      @api.create_transformation("api_test_transformation2", "crop"=>"scale", "width"=>103)
      @api.transformation("api_test_transformation2")
      @api.delete_transformation("api_test_transformation2")
      expect{@api.transformation("api_test_transformation2")}.to raise_error(Cloudinary::Api::NotFound)
    end

    it "should allow unsafe update of named transformation" do
      @api.create_transformation("api_test_transformation3", "crop"=>"scale", "width"=>102)
      @api.update_transformation("api_test_transformation3", :unsafe_update=>{"crop"=>"scale", "width"=>103})
      transformation = @api.transformation("api_test_transformation3")
      expect(transformation).not_to be_blank
      expect(transformation["info"]).to eq(["crop"=>"scale", "width"=>103])
      expect(transformation["used"]).to eq(false)
    end

  end
  it "should allow deleting implicit transformation" do
    @api.transformation("c_scale,w_100")
    @api.delete_transformation("c_scale,w_100")
    expect{@api.transformation("c_scale,w_100")}.to raise_error(Cloudinary::Api::NotFound)
  end
  
  it "should allow creating and listing upload_presets", :upload_preset => true do
    @api.create_upload_preset(:name => "api_test_upload_preset", :folder => "folder")
    @api.create_upload_preset(:name => "api_test_upload_preset2", :folder => "folder2")
    @api.create_upload_preset(:name => "api_test_upload_preset3", :folder => "folder3")
    expect(@api.upload_presets["presets"].first(3).map{|p| p["name"]}).to eq(["api_test_upload_preset3", "api_test_upload_preset2", "api_test_upload_preset"])
    @api.delete_upload_preset("api_test_upload_preset")
    @api.delete_upload_preset("api_test_upload_preset2")
    @api.delete_upload_preset("api_test_upload_preset3")
  end
  
  it "should allow getting a single upload_preset", :upload_preset => true do
    result = @api.create_upload_preset(:unsigned => true, :folder => "folder", :width => 100, :crop => :scale, :tags => ["a","b","c"], :context => {:a => "b", :c => "d"})
    name = result["name"]
    preset = @api.upload_preset(name)
    expect(preset["name"]).to eq(name)
    expect(preset["unsigned"]).to eq(true)
    expect(preset["settings"]["folder"]).to eq("folder")
    expect(preset["settings"]["transformation"]).to eq([{"width" => 100, "crop" => "scale"}])
    expect(preset["settings"]["context"]).to eq({"a" => "b", "c" => "d"})
    expect(preset["settings"]["tags"]).to eq(["a","b","c"])
    @api.delete_upload_preset(name)
  end
  
  it "should allow deleting upload_presets", :upload_preset => true do
    @api.create_upload_preset(:name => "api_test_upload_preset4", :folder => "folder")
    preset = @api.upload_preset("api_test_upload_preset4")
    @api.delete_upload_preset("api_test_upload_preset4")
    expect{preset = @api.upload_preset("api_test_upload_preset4")}.to raise_error
  end
  
  it "should allow updating upload_presets", :upload_preset => true do
    name = @api.create_upload_preset(:folder => "folder")["name"]
    preset = @api.upload_preset(name)
    @api.update_upload_preset(name, preset["settings"].merge(:colors => true, :unsigned => true, :disallow_public_id => true))
    preset = @api.upload_preset(name)
    expect(preset["name"]).to eq(name)
    expect(preset["unsigned"]).to eq(true)
    expect(preset["settings"]).to eq({"folder" => "folder", "colors" => true, "disallow_public_id" => true})
    @api.delete_upload_preset(name)
  end
  
  # this test must be last because it deletes (potentially) all dependent transformations which some tests rely on. Excluded by default.
  it "should allow deleting all resources", :delete_all=>true do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test5", :eager=>[:width=>101,:crop=>:scale])
    resource = @api.resource("api_test5")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(1)
    @api.delete_all_resources(:keep_original => true)
    resource = @api.resource("api_test5")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(0)
  end
  
  it "should support setting manual moderation status" do
    result = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    expect(result["moderation"][0]["status"]).to eq("pending")
    expect(result["moderation"][0]["kind"]).to eq("manual")
    api_result = Cloudinary::Api.update(result["public_id"], {:moderation_status => :approved})
    expect(api_result["moderation"][0]["status"]).to eq("approved")
    expect(api_result["moderation"][0]["kind"]).to eq("manual")
  end
    
  it "should support requesting raw conversion" do
    result = Cloudinary::Uploader.upload("spec/docx.docx", :resource_type => :raw)
    expect{Cloudinary::Api.update(result["public_id"], {:resource_type => :raw, :raw_convert => :illegal})}.to raise_error(Cloudinary::Api::BadRequest, /^Illegal value|not a valid/)
  end
  
  it "should support requesting categorization" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    expect{Cloudinary::Api.update(result["public_id"], {:categorization => :illegal})}.to raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting detection" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    expect{Cloudinary::Api.update(result["public_id"], {:detection => :illegal})}.to raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting auto_tagging" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    expect{Cloudinary::Api.update(result["public_id"], {:auto_tagging => 0.5})}.to raise_error(Cloudinary::Api::BadRequest, /^Must use/)
  end
  
  it "should support listing by moderation kind and value" do
    result1 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    result2 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    result3 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    Cloudinary::Api.update(result1["public_id"], {:moderation_status => :approved})
    Cloudinary::Api.update(result2["public_id"], {:moderation_status => :rejected})
    approved = Cloudinary::Api.resources_by_moderation(:manual, :approved, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    expect(approved).to include(result1["public_id"])
    expect(approved).not_to include(result2["public_id"])
    expect(approved).not_to include(result3["public_id"])
    rejected = Cloudinary::Api.resources_by_moderation(:manual, :rejected, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    expect(rejected).to include(result2["public_id"])
    expect(rejected).not_to include(result1["public_id"])
    expect(rejected).not_to include(result3["public_id"])
    pending = Cloudinary::Api.resources_by_moderation(:manual, :pending, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    expect(pending).to include(result3["public_id"])
    expect(pending).not_to include(result1["public_id"])
    expect(pending).not_to include(result2["public_id"])
  end

  it "should support listing folders" do
    pending("For this test to work, 'Auto-create folders' should be enabled in the Upload Settings, " + 
            "and the account should be empty of folders. " +
            "Comment out this line if you really want to test it.")
    Cloudinary::Uploader.upload("spec/logo.png", {:public_id => "test_folder1/item"})
    Cloudinary::Uploader.upload("spec/logo.png", {:public_id => "test_folder2/item"})
    Cloudinary::Uploader.upload("spec/logo.png", {:public_id => "test_folder1/test_subfolder1/item"})
    Cloudinary::Uploader.upload("spec/logo.png", {:public_id => "test_folder1/test_subfolder2/item"})
    result = Cloudinary::Api.root_folders
    expect(result["folders"][0]["name"]).to eq("test_folder1")
    expect(result["folders"][1]["name"]).to eq("test_folder2")
    result = Cloudinary::Api.subfolders("test_folder1")
    expect(result["folders"][0]["path"]).to eq("test_folder1/test_subfolder1")
    expect(result["folders"][1]["path"]).to eq("test_folder1/test_subfolder2")
    expect{Cloudinary::Api.subfolders("test_folder")}.to raise_error(Cloudinary::Api::NotFound)
    Cloudinary::Api.delete_resources_by_prefix("test_folder")
  end
end
