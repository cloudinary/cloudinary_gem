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
  before :each do
    Cloudinary.config({})
  end
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

    context ":client_hints" do
      shared_examples "client_hints" do
        it "should not use data-src or set responsive class" do
          expect(test_tag.name).to match( 'img')
          expect(test_tag['class']).to be_nil
          expect(test_tag['data-src']).to be_nil
          expect(test_tag['src']).to eq( "http://res.cloudinary.com/test/image/upload/dpr_auto,w_auto/sample.jpg")
        end
        it "should override :responsive" do
          Cloudinary.config.responsive = true
          expect(test_tag.name).to match( 'img')
          expect(test_tag['class']).to be_nil
          expect(test_tag['data-src']).to be_nil
          expect(test_tag['src']).to eq( "http://res.cloudinary.com/test/image/upload/dpr_auto,w_auto/sample.jpg")
        end
      end
      context "as option" do
        let(:options) { {:dpr => :auto, :cloud_name => "test", :width => "auto", :client_hints => true} }
        include_examples "client_hints"
      end
      context "as global configuration" do
        before do
          Cloudinary.config.client_hints = true
        end
        let(:options) { {:dpr => :auto, :cloud_name => "test", :width => "auto"} }
        include_examples "client_hints"
      end

      context "false" do
        let(:options) { {:width => :auto, :cloud_name => "test", :client_hints => false} }
        it "should use normal responsive behaviour" do
          expect(test_tag.name).to match( 'img')
          expect(test_tag['class']).to eq( 'cld-responsive')
          expect(test_tag['data-src']).to eq( "http://res.cloudinary.com/test/image/upload/w_auto/sample.jpg")
        end
      end
      context "width" do
        let(:options) { {:dpr => :auto, :cloud_name => "test", :width => "auto:breakpoints", :client_hints => true}}
        it "supports auto width" do
          expect(test_tag['src']).to eq( "http://res.cloudinary.com/test/image/upload/dpr_auto,w_auto:breakpoints/sample.jpg")
        end
      end
    end
  end

  context "#cl_client_hints_meta_tag" do
    it "should create a meta tag" do
      tag = TestTag.new( helper.cl_client_hints_meta_tag)
      expect(tag.name).to match('meta')
      expect(tag['content']).to eq('DPR, Viewport-Width, Width')
      expect(tag['http-equiv']).to eq('Accept-CH')
    end
  end
end
