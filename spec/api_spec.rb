require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Api do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?

  before(:all) do
    @api = Cloudinary::Api
    Cloudinary::Uploader.destroy("api_test")
    Cloudinary::Uploader.destroy("api_test2")
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test", :tags=>"api_test_tag", :context => "key=value", :eager=>[:width=>100,:crop=>:scale])
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test2", :tags=>"api_test_tag", :context => "key=value", :eager=>[:width=>100,:crop=>:scale])
    @api.delete_transformation("api_test_transformation") rescue nil
    @api.delete_transformation("api_test_transformation2") rescue nil
    @api.delete_transformation("api_test_transformation3") rescue nil
  end
  
  it "should allow listing resource_types" do
    @api.resource_types()["resource_types"].should include("image")
  end

  it "should allow listing resources" do
    resource = @api.resources()["resources"].find{|resource| resource["public_id"] == "api_test"}
    resource.should_not be_blank
    resource["type"].should == "upload" 
  end

  it "should allow listing resources with cursor" do
    result = @api.resources(:max_results=>1)
    result["resources"].should_not be_blank
    result["resources"].length.should == 1
    result["next_cursor"].should_not be_blank
    result2 = @api.resources(:max_results=>1, :next_cursor=>result["next_cursor"])
    result2["resources"].should_not be_blank
    result2["resources"].length.should == 1
    result2["resources"][0]["public_id"].should_not == result["resources"][0]["public_id"] 
  end


  it "should allow listing resources by type" do
    resource = @api.resources(:type=>"upload", :tags=>true)["resources"].find{|resource| resource["public_id"] == "api_test"}
    resource.should_not be_blank
    resource["tags"].should == ["api_test_tag"]
  end

  it "should allow listing resources by prefix" do
    resources = @api.resources(:type=>"upload", :prefix=>"api_test", :tags => true, :context => true)["resources"]
    resources.map{|resource| resource["public_id"]}.should include("api_test", "api_test2")
    resources.map{|resource| resource["tags"]}.should include(["api_test_tag"])
    resources.map{|resource| resource["context"]}.should include({"custom" => {"key" => "value"}})
  end

  it "should allow listing resources by tag" do
    resources = @api.resources_by_tag("api_test_tag", :tags => true, :context => true)["resources"]
    resources.find{|resource| resource["public_id"] == "api_test"}.should_not be_blank
    resources.map{|resource| resource["tags"]}.should include(["api_test_tag"])
    resources.map{|resource| resource["context"]}.should include({"custom" => {"key" => "value"}})
  end
  
  it "should allow listing resources by public ids" do
    resources = @api.resources_by_ids(["api_test", "api_test2"], :tags => true, :context => true)["resources"]
    resources.length.should == 2
    resources.find{|resource| resource["public_id"] == "api_test"}.should_not be_blank
    resources.map{|resource| resource["tags"]}.should include(["api_test_tag"])
    resources.map{|resource| resource["context"]}.should include({"custom" => {"key" => "value"}})
  end
  
  it "should allow listing resources in both directions" do
    asc_resources = @api.resources(:type=>"upload", :prefix=>"api_test", :direction => "asc")["resources"]
    desc_resources = @api.resources(:type=>"upload", :prefix=>"api_test", :direction => "desc")["resources"]
    # NOTE: this assumes the full list fits in a page which is the case unless resources with 'api_test' prefix were
    # uploaded to the account against which this test runs
    asc_resources.reverse.should == desc_resources
    asc_resources_alt = @api.resources(:type=>"upload", :prefix=>"api_test", :direction => 1)["resources"]
    desc_resources_alt = @api.resources(:type=>"upload", :prefix=>"api_test", :direction => -1)["resources"]
    asc_resources_alt.reverse.should == desc_resources_alt
    asc_resources.should == asc_resources_alt
    lambda{@api.resources(:type=>"upload", :prefix=>"api_test", :direction => "anythingelse")["resources"]}.should raise_error(Cloudinary::Api::BadRequest)
  end

  it "should allow get resource metadata" do
    resource = @api.resource("api_test")
    resource.should_not be_blank
    resource["public_id"].should == "api_test"
    resource["bytes"].should == 3381
    resource["derived"].length.should == 1
  end
  
  it "should allow deleting derived resource" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test3", :eager=>[:width=>101,:crop=>:scale])
    resource = @api.resource("api_test3")
    resource.should_not be_blank
    resource["derived"].length.should == 1
    derived_resource_id = resource["derived"][0]["id"]
    @api.delete_derived_resources(derived_resource_id)
    resource = @api.resource("api_test3")
    resource.should_not be_blank
    resource["derived"].length.should == 0
  end

  it "should allow deleting resources" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test3")
    resource = @api.resource("api_test3")
    resource.should_not be_blank
    @api.delete_resources(["apit_test", "api_test2", "api_test3"])
    lambda{@api.resource("api_test3")}.should raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow deleting resources by prefix" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test_by_prefix")
    resource = @api.resource("api_test_by_prefix")
    resource.should_not be_blank
    @api.delete_resources_by_prefix("api_test_by")
    lambda{@api.resource("api_test_by_prefix")}.should raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow deleting resources by tags" do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test4", :tags=>["api_test_tag_for_delete"])
    resource = @api.resource("api_test4")
    resource.should_not be_blank
    @api.delete_resources_by_tag("api_test_tag_for_delete")
    lambda{@api.resource("api_test4")}.should raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow listing tags" do
    tags = @api.tags()["tags"]
    tags.should include('api_test_tag')
  end

  it "should allow listing tag by prefix" do
    tags = @api.tags(:prefix=>"api_test")["tags"]
    tags.should include('api_test_tag')
    tags = @api.tags(:prefix=>"api_test_no_such_tag")["tags"]
    tags.should be_blank
  end
  
  it "should allow listing transformations" do
    transformation = @api.transformations()["transformations"].find{|transformation| transformation["name"] == "c_scale,w_100"}
    transformation.should_not be_blank
    transformation["used"].should == true
  end

  it "should allow getting transformation metadata" do
    transformation = @api.transformation("c_scale,w_100")
    transformation.should_not be_blank  
    transformation["info"].should == ["crop"=>"scale", "width"=>100]     
    transformation = @api.transformation("crop"=>"scale", "width"=>100)
    transformation.should_not be_blank  
    transformation["info"].should == ["crop"=>"scale", "width"=>100]     
  end
  
  it "should allow updating transformation allowed_for_strict" do
    @api.update_transformation("c_scale,w_100", :allowed_for_strict=>true)
    transformation = @api.transformation("c_scale,w_100")
    transformation.should_not be_blank  
    transformation["allowed_for_strict"].should == true
    @api.update_transformation("c_scale,w_100", :allowed_for_strict=>false)
    transformation = @api.transformation("c_scale,w_100")
    transformation.should_not be_blank  
    transformation["allowed_for_strict"].should == false
  end

  it "should allow creating named transformation" do
    @api.create_transformation("api_test_transformation", "crop"=>"scale", "width"=>102)
    transformation = @api.transformation("api_test_transformation")
    transformation.should_not be_blank  
    transformation["allowed_for_strict"].should == true
    transformation["info"].should == ["crop"=>"scale", "width"=>102]
    transformation["used"].should == false
  end

  it "should allow deleting named transformation" do
    @api.create_transformation("api_test_transformation2", "crop"=>"scale", "width"=>103)
    @api.transformation("api_test_transformation2")
    @api.delete_transformation("api_test_transformation2")
    lambda{@api.transformation("api_test_transformation2")}.should raise_error(Cloudinary::Api::NotFound)
  end  

  it "should allow unsafe update of named transformation" do
    @api.create_transformation("api_test_transformation3", "crop"=>"scale", "width"=>102)
    @api.update_transformation("api_test_transformation3", :unsafe_update=>{"crop"=>"scale", "width"=>103})
    transformation = @api.transformation("api_test_transformation3")
    transformation.should_not be_blank  
    transformation["info"].should == ["crop"=>"scale", "width"=>103]
    transformation["used"].should == false
  end

  it "should allow deleting implicit transformation" do
    @api.transformation("c_scale,w_100")
    @api.delete_transformation("c_scale,w_100")
    lambda{@api.transformation("c_scale,w_100")}.should raise_error(Cloudinary::Api::NotFound)
  end
  
  # this test must be last because it deletes (potentially) all dependent transformations which some tests rely on. Excluded by default.
  it "should allow deleting all resources", :delete_all=>true do
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test5", :eager=>[:width=>101,:crop=>:scale])
    resource = @api.resource("api_test5")
    resource.should_not be_blank
    resource["derived"].length.should == 1
    @api.delete_all_resources(:keep_original => true)
    resource = @api.resource("api_test5")
    resource.should_not be_blank
    resource["derived"].length.should == 0
  end
  
  it "should support setting manual moderation status" do
    result = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    result["moderation"][0]["status"].should == "pending"
    result["moderation"][0]["kind"].should == "manual"
    api_result = Cloudinary::Api.update(result["public_id"], {:moderation_status => :approved})
    api_result["moderation"][0]["status"].should == "approved"
    api_result["moderation"][0]["kind"].should == "manual"
  end
  
  it "should support requesting ocr info" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    lambda{Cloudinary::Api.update(result["public_id"], {:ocr => :illegal})}.should raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting raw conversion" do
    result = Cloudinary::Uploader.upload("spec/docx.docx", :resource_type => :raw)
    lambda{Cloudinary::Api.update(result["public_id"], {:resource_type => :raw, :raw_convert => :illegal})}.should raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting categorization" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    lambda{Cloudinary::Api.update(result["public_id"], {:categorization => :illegal})}.should raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting detection" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    lambda{Cloudinary::Api.update(result["public_id"], {:detection => :illegal})}.should raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end
  
  it "should support requesting ocr info" do
    result = Cloudinary::Uploader.upload("spec/logo.png")
    lambda{Cloudinary::Api.update(result["public_id"], {:auto_tagging => 0.5})}.should raise_error(Cloudinary::Api::BadRequest, /^Must use/)
  end
  
  it "should support listing by moderation kind and value" do
    result1 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    result2 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    result3 = Cloudinary::Uploader.upload("spec/logo.png", {:moderation => :manual})
    Cloudinary::Api.update(result1["public_id"], {:moderation_status => :approved})
    Cloudinary::Api.update(result2["public_id"], {:moderation_status => :rejected})
    approved = Cloudinary::Api.resources_by_moderation(:manual, :approved, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    approved.should include(result1["public_id"])
    approved.should_not include(result2["public_id"])
    approved.should_not include(result3["public_id"])
    rejected = Cloudinary::Api.resources_by_moderation(:manual, :rejected, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    rejected.should include(result2["public_id"])
    rejected.should_not include(result1["public_id"])
    rejected.should_not include(result3["public_id"])
    pending = Cloudinary::Api.resources_by_moderation(:manual, :pending, :max_results => 1000)["resources"].map{|r| r["public_id"]}
    pending.should include(result3["public_id"])
    pending.should_not include(result1["public_id"])
    pending.should_not include(result2["public_id"])
  end

end
