require 'rspec'
require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'
require 'active_support/core_ext/kernel/reporting'

RSpec.describe CloudinaryHelper do
  before :all do
    # Test the helper in the context it runs in in production
    ActionView::Base.send :include, CloudinaryHelper
  end

  let(:helper) {
    ActionView::Base.new
  }
  let(:cloud_name) {DUMMY_CLOUD}
  let(:root_path) {"http://res.cloudinary.com/#{cloud_name}"}
  let(:upload_path) {"#{root_path}/image/upload"}

  let(:options) { {} }
  before :each do
    Cloudinary.reset_config
    Cloudinary.config.enhance_image_tag = true
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

  PUBLIC_ID = 'sample.jpg'
  context "#cl_image_tag" do
    let(:test_tag) { TestTag.new( helper.cl_image_tag(PUBLIC_ID, options)) }

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
  describe "Responsive methods" do
    let (:options) {{
      :cloud_name => DUMMY_CLOUD,
      :width => ResponsiveTest::BREAKPOINTS.last,
      :height => ResponsiveTest::BREAKPOINTS.last,
      :crop => :fill}}

    describe "generate_breakpoints" do
      it "should accept breakpoint" do
        expect(helper.generate_breakpoints(:breakpoints => [1,2,3])).to eq([1,2,3])
      end
      it "should accept min_width, max_width" do
        expect(helper.generate_breakpoints(:min_width => 100, :max_width => 600, :max_images => 7)).to eq([ 100, 184, 268, 352, 436, 520, 600 ])
      end
    end
    describe "generate_scaled_url" do
      it "should generate url" do
        url = helper.generate_scaled_url('sample.jpg', 101, {:width => 200, :crop => "scale"}, options)
        expect(url).to eq("#{upload_path}/c_scale,w_200/c_scale,w_101/sample.jpg")
      end
      it "should generate url without a transformation" do
        url = helper.generate_scaled_url('sample.jpg', 101, {}, options)
        expect(url).to eq("#{upload_path}/c_scale,w_101/sample.jpg")
      end
    end
    describe "generate_srcset" do
      it "should generate a url for each breakpoint" do
        srcset = helper.generate_srcset_attribute('sample', [1,2,3], {}, options)
        expect(srcset.split(', ').length).to be(3)
      end
    end
  end

  context "#cl_picture_tag" do
    let (:options) {{
        :cloud_name => DUMMY_CLOUD,
        :width => ResponsiveTest::BREAKPOINTS.last,
        :height => ResponsiveTest::BREAKPOINTS.last,
        :crop => :fill}}
    let (:fill_trans_str) {Cloudinary::Utils.generate_transformation_string(options)}
    let (:sources) {
      [
          {
              :min_width => ResponsiveTest::BREAKPOINTS.third,
              :transformation => {:effect => "sepia", :angle => 17, :width => ResponsiveTest::BREAKPOINTS.first, :crop => :scale}
          },
          {
              :min_width => ResponsiveTest::BREAKPOINTS.second,
              :transformation => {:effect => "colorize", :angle => 18, :width => ResponsiveTest::BREAKPOINTS.second, :crop => :scale}
          },
          {
              :min_width => ResponsiveTest::BREAKPOINTS.first,
              :transformation => {:effect => "blur", :angle => 19, :width => ResponsiveTest::BREAKPOINTS.first, :crop => :scale}
          }
      ]
    }
    let(:test_tag) {TestTag.new(helper.cl_picture_tag(PUBLIC_ID, options, sources))}
    def source_url(t)
      t = Cloudinary::Utils.generate_transformation_string(t)
      upload_path + '/' + fill_trans_str + '/' + t + "/sample.jpg"
    end
    it "should create a picture tag" do
      expect(test_tag[:attributes]).to be_nil
      source_tags = test_tag.element.xpath('//source')
      expect(source_tags.length).to be(3)
      expect(test_tag.element.xpath('//img').length).to be(1)
      sources.each_with_index do |source,i|
        expect(source_tags[i].attribute('srcset').value).to eq(source_url(source[:transformation]))
      end

      [
          "(min-width: #{ResponsiveTest::BREAKPOINTS.third}px)",
          "(min-width: #{ResponsiveTest::BREAKPOINTS.second}px)",
          "(min-width: #{ResponsiveTest::BREAKPOINTS.first}px)",
      ].each_with_index do |expected, i|
        expect(source_tags[i].attribute('media').value).to eq(expected)
      end

    end

  end

  context "#cl_source_tag" do
    min_width = 100
    max_width = 399
    breakpoint_list = [min_width, 200, 300, max_width]
    common_srcset = {breakpoints: breakpoint_list}
    fill_transformation = {width: max_width, height: max_width, crop: "fill"}
    fill_transformation_str = "c_fill,h_#{max_width},w_#{max_width}"
    let (:options) {{
      :cloud_name => DUMMY_CLOUD,
      }}
    let(:test_tag) {TestTag.new(helper.cl_source_tag(PUBLIC_ID, options))}
    before(:each) do
      Cloudinary.config(cloud_name: DUMMY_CLOUD, api_secret: "1234")
    end

    it "should generate a source tag" do
      expect(test_tag.name).to eql("source")
      expect(test_tag['srcset']).to eql("#{upload_path}/sample.jpg")
    end

    it "should generate source tag with media query" do
      media = {min_width: min_width, max_width: max_width}
      tag = helper.cl_source_tag("sample.jpg", media: media)
      expected_media = "(min-width: #{min_width}px) and (max-width: #{max_width}px)".html_safe
      expected_tag = "<source srcset=\"#{upload_path}/sample.jpg\" media=\"#{expected_media}\">"
      expect(tag).to eql(expected_tag)
    end

    it "should generate source tag with responsive srcset" do
    tag = helper.cl_source_tag(PUBLIC_ID, srcset: {breakpoints: breakpoint_list})
    expect(tag).to eql(
      "<source srcset=\"" +
        "http://res.cloudinary.com/#{DUMMY_CLOUD}/image/upload/c_scale,w_100/sample.jpg 100w, " +
        "http://res.cloudinary.com/#{DUMMY_CLOUD}/image/upload/c_scale,w_200/sample.jpg 200w, " +
        "http://res.cloudinary.com/#{DUMMY_CLOUD}/image/upload/c_scale,w_300/sample.jpg 300w, " +
        "http://res.cloudinary.com/#{DUMMY_CLOUD}/image/upload/c_scale,w_399/sample.jpg 399w" +
        "\">")
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

  context "auth_token" do
    it "should add token to an image tag url" do
      tag = helper.cl_image_tag "sample.jpg",
                                :cloud_name => DUMMY_CLOUD,
                                :sign_url => true,
                                :type => "authenticated",
                                :version => "1486020273",
                                :auth_token => {key: KEY, start_time: 11111111, duration: 300}
      expect(tag).to match /<img.*src="http:\/\/res.cloudinary.com\/#{DUMMY_CLOUD}\/image\/authenticated\/v1486020273\/sample.jpg\?__cld_token__=st=11111111~exp=11111411~hmac=9bd6f41e2a5893da8343dc8eb648de8bf73771993a6d1457d49851250caf3b80.*>/

    end

  end
  describe "image_path" do

    before :all do
      class Cloudinary::Static
        class << self
          def reset_metadata
            @metadata = nil
            @static_file_config = nil
            @public_prefixes = nil
          end
        end
      end
    end

    before :each do
      @static_support = Cloudinary.config.static_image_support
      @static_file = Cloudinary::Static::METADATA_FILE
      Cloudinary.reset_config
      Cloudinary.config.enhance_image_tag = true
      Cloudinary::Static.reset_metadata
    end

    after :each do
      Cloudinary.reset_config
      Cloudinary.config.static_image_support = @static_support
      Kernel::silence_warnings {Cloudinary::Static::METADATA_FILE = @static_file}
      Cloudinary::Static.reset_metadata
    end

    context 'type=="asset"' do
      it "should not transform images staring with /" do
        expect(helper.image_path('/bar')).to eq('/bar')
      end
      it "should not transform images staring with /images unless asset is found and static_support is true" do
        Cloudinary.config.static_image_support = false
        expect(helper.image_path('/images/foo.jpg')).to eq('/images/foo.jpg')
        expect(helper.image_path('some-folder/foo.gif')).to eq("/images/some-folder/foo.gif")
        Kernel::silence_warnings { Cloudinary::Static::METADATA_FILE = "spec/sample_asset_file.tsv"}
        Cloudinary::Static.reset_metadata
        expect(helper.image_path('/images/foo.jpg'))
            .to eq("/images/foo.jpg")
        expect(helper.image_path('some-folder/foo.gif')).to eq("/images/some-folder/foo.gif")
        Cloudinary.config.static_image_support = true
        expect(helper.image_path('/images/foo.jpg')).to eq("http://res.cloudinary.com/#{Cloudinary.config.cloud_name}/image/asset/images-foo.jpg")
        expect(helper.image_path('foo.jpg')).to eq("http://res.cloudinary.com/#{Cloudinary.config.cloud_name}/image/asset/images-foo.jpg")
        expect(helper.image_path('some-folder/foo.gif')).to eq('/images/some-folder/foo.gif')
      end
    end
  end
end
