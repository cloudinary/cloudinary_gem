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
  let(:options) { {} }
  context "#cl_image_upload_tag" do
    let(:options) {{:multiple => true}}
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
    let(:test_tag) { TestTag.new( helper.cl_image_upload_tag('image_id', options)) }

    it "allow multiple upload" do
      expect(test_tag['data-cloudinary-field']).to eq('image_id[]')
      expect(test_tag['multiple']).to eq('multiple')
    end
  end
  context "#cl_upload_tag" do
    let(:options) {{:multiple => true}}
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
    let(:test_tag) { TestTag.new( helper.cl_upload_tag('image_id', options)) }

    it "allow multiple upload" do
      expect(test_tag['data-cloudinary-field']).to eq('image_id[]')
      expect(test_tag['multiple']).to eq('multiple')
    end
  end

  context "#cl_image_tag" do
    let(:test_tag) { TestTag.new( helper.cl_image_tag('sample.jpg', options)) }

    context ":responsive_width" do
      let(:options) { {:responsive_width => true, :cloud_name => "test"} }
      it "should use data-src for responsive_width" do
        expect(test_tag.name).to match( 'img')
        expect(test_tag['class']).to eq("cld-responsive")
        expect(test_tag['data-src']).to eq( "http://res.cloudinary.com/test/image/upload/c_limit,w_auto/sample.jpg")
      end
    end

    context ":dpr_auto" do
      let(:options) { {:dpr => :auto, :cloud_name => "test"} }
      it "should use data-src for dpr auto" do
        expect(test_tag.name).to match( 'img')
        expect(test_tag['class']).to eq( 'cld-hidpi')
        expect(test_tag['data-src']).to eq( "http://res.cloudinary.com/test/image/upload/dpr_auto/sample.jpg")
      end
    end
  end
end
