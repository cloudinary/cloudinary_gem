require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Api do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?

  before(:all) do
    @api = Cloudinary::Api
    Cloudinary::Uploader.destroy("api_test")
    Cloudinary::Uploader.destroy("api_test2")
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test", :tags=>"api_test_tag", :eager=>[:width=>100,:crop=>:scale])
    Cloudinary::Uploader.upload("spec/logo.png", :public_id=>"api_test2", :tags=>"api_test_tag", :eager=>[:width=>100,:crop=>:scale])
    @api.delete_transformation("api_test_transformation") rescue nil
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
    resource = @api.resources(:type=>"upload")["resources"].find{|resource| resource["public_id"] == "api_test"}
    resource.should_not be_blank
  end

  it "should allow listing resources by prefix" do
    public_ids = @api.resources(:type=>"upload", :prefix=>"api_test")["resources"].map{|resource| resource["public_id"]}
    public_ids.should include("api_test", "api_test2")
  end

  it "should allow listing resources by tag" do
    resource = @api.resources_by_tag("api_test_tag")["resources"].find{|resource| resource["public_id"] == "api_test"}
    resource.should_not be_blank
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

  it "should allow deleting implicit transformation" do
    @api.transformation("c_scale,w_100")
    @api.delete_transformation("c_scale,w_100")
    lambda{@api.transformation("c_scale,w_100")}.should raise_error(Cloudinary::Api::NotFound)
  end

end