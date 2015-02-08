require 'rspec'
require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'

helper_class = Class.new do
  include CloudinaryHelper
end

RSpec.describe CloudinaryHelper do
  let(:helper) { helper_class.new }


  context "#cl_image_upload_tag" do
    let(:options) { {} }
    subject(:input) { helper.cl_image_upload_tag(:image_id, options) }

    before do
      if defined? allow
        allow(Cloudinary::Utils).to receive_messages :cloudinary_api_url => '', :sign_request => Hash.new
        allow(helper).to receive(:build_callback_url).and_return('')
      else
        Cloudinary::Utils.should_receive(:cloudinary_api_url).and_return('')
        Cloudinary::Utils.should_receive(:sign_request).and_return(Hash.new)
        helper.should_receive(:build_callback_url).and_return('')
      end
    end

    it "allow multiple upload" do
      options[:multiple] = true
      expect(input).to include('data-cloudinary-field="image_id[]"')
      expect(input).to include('multiple="multiple"')
    end
  end

  context "#cl_image_tag" do
    subject(:input) { helper.cl_image_tag('sample.jpg', options) }

    context "responsive_width" do
      let(:options) { {responsive_width: true, cloud_name: "test"} }
      it "should use data-src for responsive_width" do
        img_tag = html_tag_matcher 'img'
        expect(input).to match img_tag
        expect(input).to include('class="cld-responsive"')
        expect(input).to include( 'data-src="http://res.cloudinary.com/test/image/upload/c_limit,w_auto/sample.jpg"')
      end
    end

    context "dpr_auto" do
      let(:options) { {dpr: :auto, cloud_name: "test"} }
      it "should use data-src for dpr auto" do
        img_tag = html_tag_matcher 'img'
        expect(input).to match(img_tag)
        expect(input).to include('data-src="http://res.cloudinary.com/test/image/upload/dpr_auto/sample.jpg"')
        expect(input).to include('class="cld-hidpi"')
      end
    end
  end
end
