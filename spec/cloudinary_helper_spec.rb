require 'spec_helper'
require 'cloudinary'
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
end
