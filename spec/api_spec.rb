require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Api do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?
  include_context "cleanup", TIMESTAMP_TAG

  prefix = "api_test_#{SUFFIX}"

  TEST_WIDTH = rand(1000)
  TEST_TRANSFOMATION = "c_scale,w_#{TEST_WIDTH}"
  PUBLIC_ID_BACKUP_1 = "#{prefix}backup_1#{Time.now.to_i}"
  PUBLIC_ID_BACKUP_2 = "#{prefix}backup_2#{Time.now.to_i}"
  METADATA_EXTERNAL_ID = "#{prefix}_metadata_external_id_#{UNIQUE_TEST_ID}"
  METADATA_DEFAULT_VALUE = "#{prefix}_metadata_default_value_#{UNIQUE_TEST_ID}"
  UNIQUE_CONTEXT_KEY = "#{prefix}_context_key_#{UNIQUE_TEST_ID}"
  UNIQUE_CONTEXT_VALUE = "#{prefix}_context_value_#{UNIQUE_TEST_ID}"
  UNIQUE_CONTEXT = "#{UNIQUE_CONTEXT_KEY}=#{UNIQUE_CONTEXT_VALUE}"
  UNIQUE_TEST_TAG_TO_ONE_IMAGE_ASSET = "#{prefix}_unique_tag_to_one_image_asset_#{UNIQUE_TEST_ID}"

  test_id_1 = "#{prefix}_1"
  test_id_2   = "#{prefix}_2"
  test_id_3   = "#{prefix}_3"
  test_key = "test_key_#{SUFFIX}"

  test_asset_id = "4af5a0d1d4047808528b5425d166c101"

  related_assets = %W[image/upload/#{test_id_2} image/upload/#{test_id_3}]
  related_asset_ids = %w(4af5a0d1d4047808528b5425d166c102 4af5a0d1d4047808528b5425d166c103)

  include_context "metadata_field",
                  :external_id => METADATA_EXTERNAL_ID,
                  :label => METADATA_EXTERNAL_ID,
                  :type => "string",
                  :default_value => METADATA_DEFAULT_VALUE

  before(:all) do
    @api = Cloudinary::Api
    @mock_api = MockedApi

    Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_1, :tags => [TEST_TAG, TIMESTAMP_TAG], :context => "key=value", :eager =>[:width =>TEST_WIDTH, :crop =>:scale])
    Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_2, :tags => [TEST_TAG, TIMESTAMP_TAG], :context => "key=value", :eager =>[:width =>TEST_WIDTH, :crop =>:scale])
    Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_3, :tags => [TEST_TAG, TIMESTAMP_TAG], :context => "key=value", :eager =>[:width =>TEST_WIDTH, :crop =>:scale])
    Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_1, :tags => [TEST_TAG, TIMESTAMP_TAG], :context => "#{test_key}=test", :eager =>[:width =>TEST_WIDTH, :crop =>:scale])
    Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_3, :tags => [TEST_TAG, TIMESTAMP_TAG], :context => "#{test_key}=tasty", :eager =>[:width =>TEST_WIDTH, :crop =>:scale])
    Cloudinary::Uploader.upload(TEST_IMG, :tags => [UNIQUE_TEST_TAG_TO_ONE_IMAGE_ASSET, TEST_TAG, TIMESTAMP_TAG], :context => UNIQUE_CONTEXT, :moderation => :manual)
  end

  after(:all) do
    # in addition to "cleanup" context
    unless Cloudinary.config.keep_test_products
      up = Cloudinary::Api.upload_presets max_results: 500
      up["presets"].each do |u|
        tags = u["settings"]["tags"]
        name = u["name"]
        if tags =~ /.*#{TIMESTAMP_TAG}.*/
          Cloudinary::Api.delete_upload_preset(name)
        end
      end
    end
  end

  it "should allow using derived_next_cursor when listing details of a single resource" do
    expected = {
      [:payload, :derived_next_cursor] => "b16b8bd80426df43a107f26b0348"
    }
    res = @mock_api.resource("test", { "derived_next_cursor" => "b16b8bd80426df43a107f26b0348"})
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should allow listing resource_types" do
    expect(@api.resource_types["resource_types"]).to include("image")
  end

  it "should allow listing resources" do
    resource = @api.resources(:max_results=>100)["resources"].find{|resource| resource["public_id"] == test_id_1}
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
    resource = @api.resources(:type=>"upload", :tags=>true, :max_results=>100)["resources"]
                 .find{|resource| resource["public_id"] == test_id_1}
    expect(resource).not_to be_blank
    expect(resource["tags"]).to match_array([TEST_TAG, TIMESTAMP_TAG])
  end

  it "should allow listing resources by prefix" do
    resources = @api.resources(:type =>"upload", :prefix => prefix, :tags => true, :context => true)["resources"]
    expect(resources.map{|resource| resource["public_id"]}).to include(test_id_1, test_id_2)
    expect(resources.map{|resource| resource["tags"]}.flatten).to include(TEST_TAG, TIMESTAMP_TAG)
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end

  it "should allow listing resources by tag" do
    resources = @api.resources_by_tag(TEST_TAG, :tags => true, :context => true)["resources"]
    expect(resources.find{|resource| resource["public_id"] == test_id_1
    }).not_to be_blank
    expect(resources.map{|resource| resource["tags"]}.flatten).to include(TEST_TAG, TIMESTAMP_TAG)
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end

  it "should allow listing resources by context" do
    resources = @api.resources_by_context(test_key)["resources"]
    expect(resources.count).to eq(2)
    resources = @api.resources_by_context(test_key,'test')["resources"]
    expect(resources.count).to eq(1)
  end

  it "should allow listing resources by public ids" do
    resources = @api.resources_by_ids([test_id_1, test_id_2], :tags => true, :context => true)["resources"]
    expect(resources.length).to eq(2)
    expect(resources.find{|resource| resource["public_id"] == test_id_1
    }).not_to be_blank
    expect(resources.map{|resource| resource["tags"]}.flatten).to include(TEST_TAG, TIMESTAMP_TAG)
    expect(resources.map{|resource| resource["context"]}).to include({"custom" => {"key" => "value"}})
  end

  it "should list uploaded assets by asset id" do
    upload = Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_1, :tags => [TEST_TAG, TIMESTAMP_TAG])
    resources = @api.resources_by_asset_ids(upload["asset_id"])["resources"]
    expect(resources).not_to be_empty
    expect(resources.length).to eq(1)
    expect(upload["public_id"]).to include(resources[0]["public_id"])
  end

  it "should list uploaded assets by asset ids" do
    upload_1 = Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_1, :tags => [TEST_TAG, TIMESTAMP_TAG])
    upload_2 = Cloudinary::Uploader.upload(TEST_IMG, :public_id => test_id_2, :tags => [TEST_TAG, TIMESTAMP_TAG])
    asset_ids = [upload_1["asset_id"], upload_2["asset_id"]]
    public_ids = [upload_1["public_id"], upload_2["public_id"]]
    resources = @api.resources_by_asset_ids(asset_ids)["resources"]
    expect(resources).not_to be_empty
    expect(resources.length).to eq(2)
    expect(public_ids).to include(resources[0]["public_id"], resources[1]["public_id"])
  end

  it "should allow listing resources by start date", :start_at => true do
    start_at = Time.now
    expected = {[:payload, :start_at] => start_at.to_s, [:payload, :direction] => "asc"}
    res = @mock_api.resources(:type =>"upload", :start_at =>start_at, :direction => "asc")
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should allow visual search" do
    image_file = File.new(TEST_IMG)
    expected = {
      :url     => /.*\/resources\/visual_search$/,
      :method  => :post,
      :payload => { "image_url" => TEST_IMAGE_URL, "image_asset_id" => test_asset_id, "text" => "sample image",
                    "image_file" => /.*UploadIO.*/},
    }

    res = @mock_api.visual_search({ "image_url"  => TEST_IMAGE_URL, "image_asset_id" => test_asset_id, "text" => "sample image",
                                    "image_file" => image_file})
    expect(res).to have_deep_hash_values_of(expected)
  end

  describe "structured metadata" do
    matcher :have_metadata do
      match do |expected|
        expect(expected["resources"]).to be_present

        expected["resources"].each do |resource|
          expect(resource).to have_key("metadata")
        end
      end

      match_when_negated do |expected|
        expect(expected["resources"]).to be_present

        expected["resources"].each do |resource|
          expect(resource).to_not have_key("metadata")
        end
      end
    end

    it "should return structured metadata in the response of the resources API response" do
      result = @api.resources(:prefix => test_id_1, :type => "upload", :metadata => true)
      expect(result).to have_metadata

      result = @api.resources(:prefix => test_id_1, :type => "upload", :metadata => false)
      expect(result).to_not have_metadata
    end

    it "should return structured metadata in the response of the resources by tag API" do
      result = @api.resources_by_tag(UNIQUE_TEST_TAG_TO_ONE_IMAGE_ASSET, :metadata => true)
      expect(result).to have_metadata

      result = @api.resources_by_tag(UNIQUE_TEST_TAG_TO_ONE_IMAGE_ASSET, :metadata => false)
      expect(result).to_not have_metadata
    end

    it "should return structured metadata in the response of the resources by context API" do
      result = @api.resources_by_context(UNIQUE_CONTEXT_KEY, UNIQUE_CONTEXT_VALUE, :metadata => true)
      expect(result).to have_metadata

      result = @api.resources_by_context(UNIQUE_CONTEXT_KEY, UNIQUE_CONTEXT_VALUE, :metadata => false)
      expect(result).to_not have_metadata
    end

    it "should return structured metadata in the response of the resources by moderation API" do
      result = @api.resources_by_moderation(:manual, :pending, :metadata => true)
      expect(result).to have_metadata

      result = @api.resources_by_moderation(:manual, :pending, :metadata => false)
      expect(result).to_not have_metadata
    end
  end

  describe ":direction" do

    it "should accept a string 'desc' and 'asc'" do
      expected = {
          :url => /.*\/resources\/image\/tags\/#{TIMESTAMP_TAG}/,
          [:payload, :direction] => "asc"
      }
      res = @mock_api.resources_by_tag(TIMESTAMP_TAG, :type =>"upload", :direction => "asc")
      expect(res).to have_deep_hash_values_of(expected)
    end
    it "should accept an integer of '1' or '-1'" do
      expected = {
          :url => /.*\/resources\/image\/tags\/#{TIMESTAMP_TAG}/,
          [:payload, :direction] => "-1"
      }
      res = @mock_api.resources_by_tag(TIMESTAMP_TAG, :type =>"upload", :direction => "-1")
      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  describe ":fields" do
    it "should allow specifying response fields as array" do
      expected = {
        :url => /.*\/resources\/image\/tags\/#{TIMESTAMP_TAG}/,
        [:payload, :fields] => "tags,secure_url"
      }
      res = @mock_api.resources_by_tag(TIMESTAMP_TAG, :type =>"upload", :fields => %w[tags secure_url])
      expect(res).to have_deep_hash_values_of(expected)
    end

    it "should allow specifying response fields as string" do
      expected = {
        :url => /.*\/resources\/image\/tags\/#{TIMESTAMP_TAG}/,
        [:payload, :fields] => "context,url"
      }
      res = @mock_api.resources_by_tag(TIMESTAMP_TAG, :type =>"upload", :fields => "context,url")
      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  it "should allow get resource metadata" do
    resource = @api.resource(test_id_1)
    expect(resource).not_to be_blank
    expect(resource["public_id"]).to eq(test_id_1)
    expect(resource["bytes"]).to eq(3381)
    expect(resource["derived"].length).to eq(1)
  end

  it "should support the quality_analysis parameter" do
    resource = @api.resource(test_id_1, :quality_analysis => true)
    expect(resource).not_to be_blank
    expect(resource).to have_key("quality_analysis")
    expect(resource["quality_analysis"]).to have_key("focus")
  end

  it "should support the accessibility_analysis parameter" do
    resource = @api.resource(test_id_1, :accessibility_analysis => true)
    expect(resource).not_to be_blank
    expect(resource).to have_key("accessibility_analysis")
  end

  it "should support the cinemagraph_analysis parameter" do
    expected = {
        [:payload, :cinemagraph_analysis] => true,
        [:method] => :get
    }
    res = @mock_api.resource(test_id_1, :cinemagraph_analysis => true)
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should allow deleting derived resource" do
    derived_resource_id = "derived_id"
    res = @mock_api.delete_derived_resources(derived_resource_id)
    expect(res).to have_deep_hash_values_of({[:payload, :derived_resource_ids] => derived_resource_id})
  end

  it "should allow deleting derived resources by transformations" do
    public_id                  = "public_id"
    transformations            = "c_crop,w_100"
    expected = {
      [:payload, :public_ids]      => public_id,
      [:payload, :transformations] => "c_crop,w_100"
    }

    res = @mock_api.delete_derived_by_transformation(public_id, transformations)
    expect(res).to have_deep_hash_values_of(expected)

    transformations            = {:crop => "crop", :width => 100}
    expected = {
      [:payload, :public_ids]      => public_id,
      [:payload, :transformations] => "c_crop,w_100"
    }

    res = @mock_api.delete_derived_by_transformation(public_id, transformations)
    expect(res).to have_deep_hash_values_of(expected)

    transformations            = [{:crop => "crop", :width => 100}, {:crop => "scale", :width => 300}]
    expected = {
      [:payload, :public_ids]      => public_id,
      [:payload, :transformations] => "c_crop,w_100|c_scale,w_300"
    }

    res = @mock_api.delete_derived_by_transformation(public_id, transformations)
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should allow deleting multiple resources and comma inclusive public IDs", :focus => true do
    res = @mock_api.delete_resources(%w[apit_test test_id_2 api_test3])
    expect(res).to have_deep_hash_values_of({[:payload, :public_ids] => ["apit_test", "test_id_2", "api_test3"]})
    res = @mock_api.delete_resources("apit_test,test_id_2,api_test3")
    expect(res).to have_deep_hash_values_of({[:payload, :public_ids] => "apit_test,test_id_2,api_test3"})
  end

  it "should allow deleting resource transformations" do
    resource = Cloudinary::Uploader.upload(TEST_IMG, :eager => [{:width=>101,:crop=>:scale}, {:width=>200,:crop=>:crop}])
    public_id = resource["public_id"]
    expect(resource).not_to be_blank
    derived = resource["eager"].map{|d| d["transformation"]}
    expect(derived).to include("c_scale,w_101", "c_crop,w_200")
    @api.delete_resources([public_id], :transformations => "c_crop,w_200")
    resource = @api.resource(public_id)
    derived = resource["derived"].map{|d| d["transformation"]}
    expect(derived).not_to include("c_crop,w_200")
    expect(derived).to include("c_scale,w_101")
  end

  it "should allow deleting resources by prefix" do
    res = @mock_api.delete_resources_by_prefix("api_test_by")
    expect(res).to have_deep_hash_values_of({[:payload, :prefix] => "api_test_by"})
  end

  it "should allow deleting resources by tags" do
    res = @mock_api.delete_resources_by_tag("api_test_tag_for_delete")
    expect(res).to have_deep_hash_values_of(:url => /.*\/tags\/api_test_tag_for_delete$/)
  end

  describe 'related assets' do
    it "should allow adding related assets" do
      expected = {
                   :url => /.*\/resources\/related_assets\/image\/upload\/#{test_id_1}$/,
                   :method => :post,
                   :payload => { "assets_to_relate" => related_assets },
      }
      res = @mock_api.add_related_assets(test_id_1, related_assets)
      expect(res).to have_deep_hash_values_of(expected)
    end

    it "should allow adding related assets by asset ids" do
      expected = {
        :url => /.*\/resources\/related_assets\/#{test_asset_id}$/,
        :method => :post,
        :payload => { "assets_to_relate" => related_asset_ids },
      }
      res = @mock_api.add_related_assets_by_asset_ids(test_asset_id, related_asset_ids)
      expect(res).to have_deep_hash_values_of(expected)
    end

    it "should allow deleting related assets" do
      expected = {
        :url => /.*\/resources\/related_assets\/image\/upload\/#{test_id_1}$/,
        :method => :delete,
        :payload => { "assets_to_unrelate" => related_assets },

      }
      res = @mock_api.delete_related_assets(test_id_1, related_assets)
      expect(res).to have_deep_hash_values_of(expected)
    end

    it "should allow deleting related assets by asset ids" do
      expected = {
        :url => /.*\/resources\/related_assets\/#{test_asset_id}$/,
        :method => :delete,
        :payload => { "assets_to_unrelate" => related_asset_ids },
      }
      res = @mock_api.delete_related_assets_by_asset_ids(test_asset_id, related_asset_ids)
      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  it "should allow listing tags" do
    tags = @api.tags(:max_results => 500)["tags"]
    expect(tags).to include(TEST_TAG)
  end

  it "should allow listing tag by prefix" do
    tags = @api.tags(:prefix=> TEST_TAG)["tags"]
    expect(tags).to include(TIMESTAMP_TAG)
    tags = @api.tags(:prefix=>"api_test_no_such_tag")["tags"]
    expect(tags).to be_blank
  end

  it "should get uploaded image details by asset_id" do
    result = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG])
    resource = @api.resource_by_asset_id(result["asset_id"])
    expect(resource).not_to be_empty
    expect(resource["asset_id"]).to eq(result["asset_id"])
    expect(resource).not_to have_key("accessibility_analysis")
    expect(resource).not_to have_key("colors")
    expect(resource).not_to have_key("exif")
    expect(resource).not_to have_key("faces")
  end

  it "should get uploaded image details by asset_id with extra info" do
    result = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG])
    resource = @api.resource_by_asset_id(result["asset_id"], { colors: true, faces: true, exif: true })
    expect(resource).not_to be_empty
    expect(resource["asset_id"]).to eq(result["asset_id"])
    expect(resource).to have_key("colors")
    expect(resource).to have_key("exif")
    expect(resource).to have_key("faces")
  end

  describe "backup resource" do
    let(:public_id) { "api_test_backup_#{SUFFIX}" }

    before(:each) do
      Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => public_id, :backup => true)
      response = @api.resource(public_id)
      expect(response).not_to be_nil
    end

    it "should return the asset details together with all of its backed up versions when versions is true" do
      resource = @api.resource(public_id, :versions => true)

      expect(resource["versions"]).to be_an_instance_of(Array)
    end

    it "should return the asset details together without backed up versions when versions is false" do
      resource = @api.resource(public_id, :versions => false)

      expect(resource["versions"]).to be_nil
    end
  end

  describe 'transformations' do
    it "should allow listing transformations" do
      transformations = @api.transformations()["transformations"]
      t0 = transformations[0]
      expect(t0).not_to be_empty
      expect(t0).to have_key("used")
    end

    it "should allow getting transformation metadata" do
      transformation = @api.transformation(TEST_TRANSFOMATION)
      expect(transformation).not_to be_blank
      expect(transformation["info"]).to eq(["crop" => "scale", "width" => TEST_WIDTH])
      transformation = @api.transformation("crop" => "scale", "width" => TEST_WIDTH)
      expect(transformation).not_to be_blank
      expect(transformation["info"]).to eq(["crop" => "scale", "width" => TEST_WIDTH])
    end

    it "should allow updating transformation allowed_for_strict" do
      @api.update_transformation(TEST_TRANSFOMATION, :allowed_for_strict => true)
      transformation = @api.transformation(TEST_TRANSFOMATION)
      expect(transformation).not_to be_blank
      expect(transformation["allowed_for_strict"]).to eq(true)
      @api.update_transformation(TEST_TRANSFOMATION, :allowed_for_strict => false)
      transformation = @api.transformation(TEST_TRANSFOMATION)
      expect(transformation).not_to be_blank
      expect(transformation["allowed_for_strict"]).to eq(false)
    end

    it "should fetch two different derived images using next_cursor" do
      result = @api.transformation(TEST_TRANSFOMATION, :max_results=>1)
      expect(result["derived"]).not_to be_blank
      expect(result["derived"].length).to eq(1)
      expect(result["next_cursor"]).not_to be_blank
      result2 = @api.transformation(TEST_TRANSFOMATION, :max_results=>1, :next_cursor=>result["next_cursor"])
      expect(result2["derived"]).not_to be_blank
      expect(result2["derived"].length).to eq(1)
      expect(result2["derived"][0]["id"]).not_to eq(result["derived"][0]["id"] )
    end

    describe "named transformations" do
      it "should allow creating named transformation" do
        public_id = "api_test_transformation_#{Time.now.to_i}"
        @api.create_transformation(public_id, "crop" => "scale", "width" => 102)
        transformation = @api.transformation(public_id)
        expect(transformation).not_to be_blank
        expect(transformation["allowed_for_strict"]).to eq(true)
        expect(transformation["info"]).to eq(["crop" => "scale", "width" => 102])
        expect(transformation["used"]).to eq(false)
      end

      it "should allow deleting named transformation" do
        public_id = "api_test_transformation_#{Time.now.to_i}"
        expected = {
          :url => /.*\/transformations$/,
          :method => :delete,
          [:payload, :transformation] => public_id
        }
        res = @mock_api.delete_transformation(public_id)
        expect(res).to have_deep_hash_values_of(expected)
      end

      it "should allow unsafe update of named transformation" do
        public_id = "api_test_transformation_#{Time.now.to_i}"
        expected = {
            :url => /.*\/transformations$/,
            :method => :put,
            [:payload, :unsafe_update] => "c_scale,w_103",
            [:payload, :transformation] => public_id}
        res = @mock_api.update_transformation(public_id, :unsafe_update => { "crop" => "scale", "width" => 103 })
        expect(res).to have_deep_hash_values_of(expected)
      end

      it "should allow listing of named transformations" do
        res= @mock_api.transformations :named => true
        expect(res).to have_deep_hash_values_of([:payload, :named ]=> true)
      end

    end
    it "should allow deleting implicit transformation" do
      @api.transformation(TEST_TRANSFOMATION)
      @api.delete_transformation(TEST_TRANSFOMATION)
      expect { @api.transformation(TEST_TRANSFOMATION) }.to raise_error(Cloudinary::Api::NotFound)
    end
  end

  it "should allow creating upload_presets" do
    expected = {:url => /.*\/upload_presets$/,
                [:payload, :name] => "new_preset",
                [:payload, :folder] => "some_folder",
                [:payload, :eval] => EVAL_STR,
                [:payload, :on_success] => ON_SUCCESS_STR}


    res = @mock_api.create_upload_preset(:name       => "new_preset",
                                         :folder     => "some_folder",
                                         :eval       => EVAL_STR,
                                         :on_success => ON_SUCCESS_STR,
                                         :tags       => [TEST_TAG, TIMESTAMP_TAG])
    expect(res).to have_deep_hash_values_of(expected)
  end

  describe "upload_presets" do
    it 'should not accept parameters' do
      expected = {
          :url => /.*\/upload_presets/,
          [:payload, :next_cursor] => 1234567,
          [:payload, :max_results] => 10
      }
      res = @mock_api.upload_presets :next_cursor => 1234567, :max_results => 10
      expect(res).to have_deep_hash_values_of(expected)
    end
  end
  it "should allow getting a single upload_preset", :upload_preset => true do
    result = @api.create_upload_preset(:unsigned => true, :folder => "folder", :width => 100, :crop => :scale, :tags => ["a","b","c", TEST_TAG, TIMESTAMP_TAG], :context => {:a => "b", :c => "d"})
    name = result["name"]
    preset = @api.upload_preset(name)
    expect(preset["name"]).to eq(name)
    expect(preset["unsigned"]).to eq(true)
    expect(preset["settings"]["folder"]).to eq("folder")
    expect(preset["settings"]["transformation"]).to eq([{"width" => 100, "crop" => "scale"}])
    expect(preset["settings"]["context"]).to eq({"a" => "b", "c" => "d"})
    expect(preset["settings"]["tags"]).to eq(["a","b","c", TEST_TAG, TIMESTAMP_TAG])
  end

  it "should allow deleting upload_presets", :upload_preset => true do
    id = "#{prefix}_upload_preset"
    @api.create_upload_preset(:name => id, :folder => "folder", :tags => [TEST_TAG, TIMESTAMP_TAG])
    preset = @api.upload_preset(id)
    @api.delete_upload_preset(id)
    expect{preset = @api.upload_preset(id)}.to raise_error(Cloudinary::Api::NotFound)
  end

  it "should allow updating upload_presets", :upload_preset => true do
    name = @api.create_upload_preset(:folder => "folder", :tags => [TEST_TAG, TIMESTAMP_TAG])["name"]
    preset = @api.upload_preset(name)
    @api.update_upload_preset(name, preset["settings"].merge(:colors => true,
                                                             :unsigned => true,
                                                             :disallow_public_id => true,
                                                             :eval => EVAL_STR,
                                                             :on_success => ON_SUCCESS_STR))
    preset = @api.upload_preset(name)
    expect(preset["name"]).to eq(name)
    expect(preset["unsigned"]).to eq(true)
    expect(preset["settings"]).to eq("folder" => "folder",
                                     "colors" => true,
                                     "disallow_public_id" => true,
                                     "eval" => EVAL_STR,
                                     "on_success" => ON_SUCCESS_STR,
                                     "tags" => [TEST_TAG, TIMESTAMP_TAG])
  end

  # this test must be last because it deletes (potentially) all dependent transformations which some tests rely on. Excluded by default.
  skip "should allow deleting all resources", :delete_all=>true do
    Cloudinary::Uploader.upload(TEST_IMG, :public_id=>"api_test5", :eager=>[:width=>101,:crop=>:scale], :tags => [TEST_TAG, TIMESTAMP_TAG])
    resource = @api.resource("api_test5")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(1)
    @api.delete_all_resources(:keep_original => true)
    resource = @api.resource("api_test5")
    expect(resource).not_to be_blank
    expect(resource["derived"].length).to eq(0)
  end

  it "should support setting manual moderation status" do
    result = Cloudinary::Uploader.upload(TEST_IMG, {:moderation => :manual, :tags => [TEST_TAG, TIMESTAMP_TAG]})
    expect(result["moderation"][0]["status"]).to eq("pending")
    expect(result["moderation"][0]["kind"]).to eq("manual")
    api_result = Cloudinary::Api.update(result["public_id"], {:moderation_status => :approved})
    expect(api_result["moderation"][0]["status"]).to eq("approved")
    expect(api_result["moderation"][0]["kind"]).to eq("manual")
  end

  it "should support requesting raw conversion" do
    result = Cloudinary::Uploader.upload(TEST_RAW, :resource_type => :raw, :tags => [TEST_TAG, TIMESTAMP_TAG])
    expect{Cloudinary::Api.update(result["public_id"], {:resource_type => :raw, :raw_convert => :illegal})}.to raise_error(Cloudinary::Api::BadRequest, /^Illegal value|not a valid/)
  end

  it "should support requesting categorization" do
    result = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG])
    expect{Cloudinary::Api.update(result["public_id"], {:categorization => :illegal})}.to raise_error(Cloudinary::Api::BadRequest, /^Illegal value/)
  end

  it "should support requesting detection with server notification", :focus => true do
    expected = {
      [:payload, :detection] => "adv_face",
      [:payload, :notification_url] => "http://example.com"
    }
    res = @mock_api.update("public_id", { :detection => "adv_face", :notification_url => "http://example.com"})
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should support display name and unique display name", :focus => true do
    expected = {
      [:payload, :asset_folder] => "dummy_folder",
      [:payload, :display_name] => "dummy_display_name",
      [:payload, :unique_display_name] => true
    }
    res = @mock_api.update("public_id", {
      :asset_folder        => "dummy_folder",
      :display_name        => "dummy_display_name",
      :unique_display_name => true })
    expect(res).to have_deep_hash_values_of(expected)
  end

  it "should support requesting auto_tagging" do
    res = @mock_api.update("public_id", {:auto_tagging => 0.5})
    expect(res).to have_deep_hash_values_of([:payload, :auto_tagging] => 0.5)
  end

  it "should support updating metadata" do
    res = @mock_api.update("public_id", { :metadata => { :key => :value } })
    expect(res).to have_deep_hash_values_of([:payload, :metadata] => "key=value")
  end

  it "should support updating metadata with clear_invalid" do
    res = @mock_api.update("public_id", { :clear_invalid => true })
    expect(res).to have_deep_hash_values_of([:payload, :clear_invalid] => 1)
  end

  it "should support quality_override" do
    ['auto:advanced', 'auto:best', '80:420', 'none'].each do |q|
      expected = {[:payload, :quality_override] => q}
      res = @mock_api.update Pathname.new(TEST_IMG), :quality_override => q
      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  it "should support listing by moderation kind and value" do
    res = @mock_api.resources_by_moderation(:manual, :approved, :max_results => 1000)
    expect(res).to have_deep_hash_values_of([:url] => /.*manual\/approved$/, [:payload, :max_results] => 1000)
  end

  it "should support the api_proxy parameter" do
    proxy = "https://myuser:mypass@my.proxy.com"
    expected = {
      [:request, :proxy, :uri] => proxy
    }
    res = @mock_api.resource(test_id_1, :api_proxy => proxy)
    expect(res).to have_deep_hash_values_of(expected)
  end

  describe 'usage' do
    let(:yesterday) { Date.today - 1 }

    it 'should return usage values for a specific date' do
      result = @api.usage(:date => yesterday)
      expect(result).to be_a_usage_result

      # verify the structure of the response is that of a single day.
      expect(result['bandwidth']).not_to have_key('limit')
      expect(result['bandwidth']).not_to have_key('used_percent')
    end

    it 'should support usage API call' do
      result = @api.usage(:date => yesterday)
      expect(result).to be_a_usage_result

      result = @api.usage(:date => Cloudinary::Utils.to_usage_api_date_format(yesterday))
      expect(result).to be_a_usage_result

      result = @api.usage
      expect(result).to be_a_usage_result
    end
  end

  describe 'config' do
    let(:cloud_name) { Cloudinary.config.cloud_name }

    it 'should return the correct cloud name' do
      res = @api.config
      expect(res['cloud_name']).to eq(cloud_name)
    end

    it 'should not include settings by default' do
      res = @api.config
      expect(res).not_to have_key('settings')
    end

    it 'should include settings when requested' do
      res = @api.config(settings: 'true')
      expect(res).to have_key('settings')
    end
  end

  it 'should list assets from an asset folder' do
    expected = { #resources/by_asset_folder
        [:url] => /.*\/resources\/by_asset_folder$/,
        [:method] => :get,
        [:payload, :asset_folder] => UNIQUE_TEST_FOLDER,
    }
    res = @mock_api.resources_by_asset_folder(UNIQUE_TEST_FOLDER)
    expect(res).to have_deep_hash_values_of(expected)
  end

  describe 'folders' do
    it 'should create folder' do
      expected = {
          [:url] => /.*\/folders\/#{UNIQUE_TEST_FOLDER}$/,
          [:method] => :post
      }
      res = @mock_api.create_folder(UNIQUE_TEST_FOLDER)
      expect(res).to have_deep_hash_values_of(expected)
    end
    it 'should rename folder' do
      expected = {
        [:url] => /.*\/folders\/#{UNIQUE_TEST_FOLDER}$/,
        [:method] => :put,
        [:payload, :to_folder] => UNIQUE_TEST_FOLDER + "_new",
      }
      res = @mock_api.rename_folder(UNIQUE_TEST_FOLDER, UNIQUE_TEST_FOLDER + "_new")
      expect(res).to have_deep_hash_values_of(expected)
    end
    it "should support listing folders" do
      res = @mock_api.root_folders
      expect(res).to have_deep_hash_values_of([:url] => /.*\/folders$/, [:method] => :get)
      res = @mock_api.subfolders("test_folder1")
      expect(res).to have_deep_hash_values_of([:url] => /.*\/folders\/test_folder1$/, [:method] => :get)
    end
    it "should URL escape the folder name" do
      expected = {
        [:url] => %r".*\/folders\/sub%5Efolder%20test$"
      }
      res = @mock_api.subfolders("sub^folder test")
      expect(res).to have_deep_hash_values_of(expected)
    end
    it "should throw if folder is missing" do
      expect{Cloudinary::Api.subfolders("I_do_not_exist")}.to raise_error(Cloudinary::Api::NotFound)
    end
    it 'should include max_results and next_cursor for root_folders call' do
      expected = {
          [:payload, :max_results] => 3,
          [:payload, :next_cursor] => NEXT_CURSOR,
      }
      res = @mock_api.root_folders :max_results => 3, :next_cursor => NEXT_CURSOR
      expect(res).to have_deep_hash_values_of(expected)
    end
    it 'should include max_results and next_cursor for subfolders call' do
      expected = {
          [:payload, :max_results] => 3,
          [:payload, :next_cursor] => NEXT_CURSOR,
      }
      res = @mock_api.subfolders GENERIC_FOLDER_NAME, :max_results => 3, :next_cursor => NEXT_CURSOR
      expect(res).to have_deep_hash_values_of(expected)
    end
    it "should support deleting a folder" do
      expected = {
        :url => %r"/folders/#{GENERIC_FOLDER_NAME}$",
        :method => :delete
      }
      res = @mock_api.delete_folder(GENERIC_FOLDER_NAME)
      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  describe '.restore'  do
    let(:public_id) { "api_test_restore#{SUFFIX}" }

    before(:each) do
      Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => public_id, :backup => true)
      sleep(2)

      resource = @api.resource(public_id)
      expect(resource).not_to be_nil
      expect(resource["bytes"]).to eq(3381)

      @api.delete_resources(public_id)

      resource = @api.resource(public_id)
      expect(resource).not_to be_nil
      expect(resource["bytes"]).to eq(0)
      expect(resource["placeholder"]).to eq(true)
    end

    it 'should restore a deleted resource' do
      response = @api.restore([public_id])

      info = response[public_id]
      expect(info).not_to be_nil
      expect(info["bytes"]).to eq(3381)

      resource = @api.resource(public_id)
      expect(resource).not_to be_nil
      expect(resource["bytes"]).to eq(3381)
    end

    it "should restore different versions of a deleted asset" do
      # Upload the same file twice (upload->delete->upload->delete)

      # Upload and delete a file
      first_upload = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => PUBLIC_ID_BACKUP_1, :backup => true)
      sleep(1)

      first_delete = @api.delete_resources([PUBLIC_ID_BACKUP_1])

      # Upload and delete it again, this time add angle to create a different 'version'
      second_upload = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => PUBLIC_ID_BACKUP_1, :transformation => { :angle => 0 }, :backup => true)
      sleep(1)

      second_delete = @api.delete_resources([PUBLIC_ID_BACKUP_1])
      sleep(1)

      # Ensure all files were uploaded correctly
      expect(first_upload).not_to be_nil
      expect(second_upload).not_to be_nil

      # Sanity, ensure these uploads are different before we continue
      expect(first_upload["bytes"]).not_to equal(second_upload["bytes"])

      # Ensure all files were deleted correctly
      expect(first_delete).to have_key("deleted")
      expect(second_delete).to have_key("deleted")

      # Get the versions of the deleted asset
      get_versions_resp = @api.resource(PUBLIC_ID_BACKUP_1, :versions => true)

      first_asset_version = get_versions_resp["versions"][0]["version_id"]
      second_asset_version = get_versions_resp["versions"][1]["version_id"]

      # Restore first version, ensure it's equal to the upload size
      sleep(1)
      first_ver_restore = @api.restore([PUBLIC_ID_BACKUP_1], :versions => [first_asset_version])
      expect(first_ver_restore[PUBLIC_ID_BACKUP_1]["bytes"]).to eq(first_upload["bytes"])

      # Restore second version, ensure it's equal to the upload size
      sleep(1)
      second_ver_restore = @api.restore([PUBLIC_ID_BACKUP_1], { :versions => [second_asset_version] })
      expect(second_ver_restore[PUBLIC_ID_BACKUP_1]["bytes"]).to eq(second_upload["bytes"])

      # Cleanup
      final_delete_resp = @api.delete_resources([PUBLIC_ID_BACKUP_1])
      expect(final_delete_resp).to have_key("deleted")
    end

    it "should restore two different deleted assets" do
      # Upload two different files
      first_upload = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => PUBLIC_ID_BACKUP_1, :backup => true)
      second_upload = Cloudinary::Uploader.upload(TEST_IMG, :tags => [TEST_TAG, TIMESTAMP_TAG], :public_id => PUBLIC_ID_BACKUP_2, :transformation => { :angle => 0 }, :backup => true)

      # delete both resources
      delete_all = @api.delete_resources([PUBLIC_ID_BACKUP_1, PUBLIC_ID_BACKUP_2])

      # Expect correct deletion of the assets
      expect(delete_all["deleted"][PUBLIC_ID_BACKUP_1]).to eq("deleted")
      expect(delete_all["deleted"][PUBLIC_ID_BACKUP_2]).to eq("deleted")

      get_first_asset_version = @api.resource(PUBLIC_ID_BACKUP_1, :versions => true)
      get_second_asset_version = @api.resource(PUBLIC_ID_BACKUP_2, :versions => true)

      first_asset_version = get_first_asset_version["versions"][0]["version_id"]
      second_asset_version = get_second_asset_version["versions"][0]["version_id"]

      ids_to_restore = [PUBLIC_ID_BACKUP_1, PUBLIC_ID_BACKUP_2]
      versions_to_restore = [first_asset_version, second_asset_version]

      restore = @api.restore(ids_to_restore, :versions => versions_to_restore)

      # Expect correct restorations
      expect(restore[PUBLIC_ID_BACKUP_1]["bytes"]).to eq(first_upload["bytes"])
      expect(restore[PUBLIC_ID_BACKUP_2]["bytes"]).to eq(second_upload["bytes"])

      # Cleanup
      final_delete = @api.delete_resources([PUBLIC_ID_BACKUP_1, PUBLIC_ID_BACKUP_2])

      # Expect correct deletion of the assets
      expect(final_delete["deleted"][PUBLIC_ID_BACKUP_1]).to eq("deleted")
      expect(final_delete["deleted"][PUBLIC_ID_BACKUP_2]).to eq("deleted")
    end
  end

  describe 'create_upload_mapping' do
    mapping = "api_test_upload_mapping#{rand(100000)}"
    it 'should create mapping' do
      res = @mock_api.create_upload_mapping(mapping, :template =>"http://cloudinary.com")
      expect(res).to have_deep_hash_values_of([:payload, :template] => "http://cloudinary.com")
      res = @mock_api.update_upload_mapping(mapping, "template" =>"http://res.cloudinary.com")
      expect(res).to have_deep_hash_values_of([:payload, :template] => "http://res.cloudinary.com")
    end
  end

  describe "access_mode", :with_retries do
    i = 0

    public_id = ""
    access_mode_tag = ''
    before(:each) do
      i += 1
      access_mode_tag = TEST_TAG + "access_mode" + i.to_s
      result = Cloudinary::Uploader.upload TEST_IMG, access_mode: "authenticated", tags: [TEST_TAG, TIMESTAMP_TAG, access_mode_tag]
      public_id = result["public_id"]
      expect(result["access_mode"]).to eq("authenticated")
    end

    it "should update access mode by ids" do
      result = Cloudinary::Api.update_resources_access_mode_by_ids "public", [public_id]

      expect(result["updated"]).to be_an_instance_of(Array)
      expect(result["updated"].length).to eq(1)
      resource = result["updated"][0]
      expect(resource["public_id"]).to eq(public_id)
      expect(resource["access_mode"]).to eq('public')
    end
    it "should update access mode by prefix" do
      result = Cloudinary::Api.update_resources_access_mode_by_prefix "public", public_id[0..-3]

      expect(result["updated"]).to be_an_instance_of(Array)
      expect(result["updated"].length).to eq(1)
      resource = result["updated"][0]
      expect(resource["public_id"]).to eq(public_id)
      expect(resource["access_mode"]).to eq('public')
    end
    it "should update access mode by tag" do
      result = Cloudinary::Api.update_resources_access_mode_by_tag "public", access_mode_tag

      expect(result["updated"]).to be_an_instance_of(Array)
      expect(result["updated"].length).to eq(1)
      resource = result["updated"][0]
      expect(resource["public_id"]).to eq(public_id)
      expect(resource["access_mode"]).to eq('public')
    end
  end

  context "resource of type authenticated" do
    i = 0
    bytes = nil
    publicId = ""
    publish_resource_tag = "publish_resource_tag"
    before(:each) do
      i += 1
      result = Cloudinary::Uploader.upload TEST_IMG, type: "authenticated", tags: [TEST_TAG, TIMESTAMP_TAG, publish_resource_tag], transformation: {width: 100*i, crop: "scale"}
      publicId = result["public_id"]
      expect(result["type"]).to eq("authenticated")
    end

    it "should publish resources by ids" do
      result = Cloudinary::Api.publish_by_ids( [publicId])

      expect(result["published"]).to be_an_instance_of(Array)
      expect(result["published"].length).to eq(1)

      resource = result["published"][0]

      expect(resource["public_id"]).to eq(publicId)
      expect(resource["type"]).to eq('upload')

      bytes = resource["bytes"]
    end
    it "should publish resources by prefix and overwrite" do
      result = Cloudinary::Api.publish_by_prefix(publicId[0..-3], overwrite: true)

      expect(result["published"]).to be_an_instance_of(Array)
      expect(result["published"].length).to eq(1)

      resource = result["published"][0]

      expect(resource["public_id"]).to eq(publicId)
      expect(resource["bytes"]).not_to eq(bytes)
      expect(resource["type"]).to eq('upload')

      bytes = resource["bytes"]
    end
    it "should publish resources by tag and overwrite" do
      result = Cloudinary::Api.publish_by_tag(publish_resource_tag, overwrite: true)

      expect(result["published"]).to be_an_instance_of(Array)
      expect(result["published"].length).to eq(1)

      resource = result["published"][0]

      expect(resource["public_id"]).to eq(publicId)
      expect(resource["bytes"]).not_to eq(bytes)
      expect(resource["type"]).to eq('upload')

      bytes = resource["bytes"]
    end
  end
  describe "json breakpoints" do
    it "should retrieve breakpoints as json array" do
      bp = Cloudinary::Api.get_breakpoints(test_id_1, srcset: {min_width:10, max_width:2000, bytes_step: 10, max_images: 20})
      expect(bp).to be_truthy
    end
  end

  describe "Analysis API" do
    it "should analyze URI" do
      expected = {
        :url     => /.*\/v2\/.*\/analysis\/analyze\/uri$/,
        :method  => :post,
        :payload => {
          "analysis_type" => "captioning",
          "uri"           => "https://res.cloudinary.com/demo/image/upload/dog",
          "parameters"    => { "custom" => { "model_name" => "my_model", "model_version" => 1 } } },
      }

      res = @mock_api.analyze("uri", "captioning",
                              :uri        => "https://res.cloudinary.com/demo/image/upload/dog",
                              :parameters => { custom: { model_name: "my_model", model_version: 1 } })
      expect(res).to have_deep_hash_values_of(expected)
    end
  end
end

describe Cloudinary::Api::Response do
  let(:api_response) { described_class.new }

  shared_examples 'a Hash' do
    it 'inherits from Hash' do
      expect(api_response).to be_a Hash
    end
  end

  context 'when there is no argument given on instantiation' do
    it 'does not raise an error' do
      expect { api_response }.to_not raise_error
    end

    it_behaves_like 'a Hash'
  end

  context 'when the response is nil' do
    it 'does not raise an error' do
      expect { described_class.new nil }.to_not raise_error
    end

    it_behaves_like 'a Hash'
  end

  context 'when the response is present' do
    let(:body)          { { 'foo' => 'bar' } }
    let(:http_response) { double code: 200, body: body.to_json, headers: { x_featureratelimit_reset: Time.new.to_s } }
    let(:api_response)  { described_class.new http_response }

    it 'sets the instantiated self as the parsed response which is a Hash' do
      expect(api_response).to eq body
    end

    it_behaves_like 'a Hash'
  end

  it 'tests rate limits' do
    results = []
    results << Cloudinary::Api.ping
    results << Cloudinary::Api.root_folders
    results << Cloudinary::Api.resource_types

    results.each do |result|
      expect(result.rate_limit_reset_at).to be_kind_of(Time)
      expect(result.rate_limit_allowed).to be_kind_of(Integer)
      expect(result.rate_limit_remaining).to be_kind_of(Integer)

      expect(result.rate_limit_allowed).to be > 0
      expect(result.rate_limit_remaining).to be > 0
      expect(result.rate_limit_reset_at).not_to be_nil
    end
  end
end
