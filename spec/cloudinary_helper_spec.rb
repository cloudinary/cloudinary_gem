require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'

helper_class = Class.new do
  include CloudinaryHelper
end

describe CloudinaryHelper do
  let(:helper) { helper_class.new }


  context "#cl_image_upload_tag" do
    let(:options) { {} }
    subject(:input) { helper.cl_image_upload_tag(:image_id, options) }

    before do
      Cloudinary::Utils.stub(:cloudinary_api_url)
      Cloudinary::Utils.stub(:sign_request)
      helper.stub(:build_callback_url)
    end

    it "allow multiple upload" do
      options[:multiple] = true
      expect(input).to include('data-cloudinary-field="image_id[]"')
      expect(input).to include('multiple="multiple"')
    end
  end

  context "#cl_image_tag" do
    subject(:input) { helper.cl_image_tag("sample.jpg", options) }

    context "responsive_width" do
      let(:options) { {responsive_width: true, cloud_name: "test"} }
      it "should use data-src for responsive_width" do
        expect(input).to eq("<img class=\"cld-responsive\" data-src=\"http://res.cloudinary.com/test/image/upload/c_limit,w_auto/sample.jpg\"></img>")
      end
    end

    context "dpr_auto" do
      let(:options) { {dpr: :auto, cloud_name: "test"} }
      it "should use data-src for dpr auto" do
        expect(input).to eq("<img class=\"cld-hidpi\" data-src=\"http://res.cloudinary.com/test/image/upload/dpr_auto/sample.jpg\"></img>")
      end
    end
  end
end
