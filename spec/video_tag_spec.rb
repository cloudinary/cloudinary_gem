require 'rspec'
require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'

include CloudinaryHelper

describe CloudinaryHelper do
  before(:each) do
    Cloudinary.config do |config|
      config.cloud_name          = "test123"
      config.secure_distribution = nil
      config.private_cdn         = false
      config.secure              = false
      config.cname               = nil
      config.cdn_subdomain       = false
      config.api_key             = "1234"
      config.api_secret          = "b"
    end
  end
  let(:helper) { (Class.new { include CloudinaryHelper }).new }

  describe 'cl_video_tag' do
    let(:basic_options) { { :cloud_name => "test123", :html_height => "100px", :html_width => "200px" } }
    let(:options) { basic_options }
    let(:test_tag) {
      TestTag.new helper.cl_video_tag("movie", options) }
    context "when options include video tag attributes" do
      let(:options) { basic_options.merge({ :autoplay => true,
                                            :controls => true,
                                            :loop     => true,
                                            :muted    => true,
                                            :preload  => true }) }
      it "should suport video tag parameters" do
        expect(test_tag.attributes.keys).to include("autoplay", "controls", "loop", "muted", "poster", "preload")
      end
    end
    { :autoplay => true, :controls => false, :loop => false, :muted => true, :preload => true }

    context 'when given transformations' do
      let(:options) {
        basic_options.merge(
          :source_types => "mp4",
          :html_height  => "100",
          :html_width   => "200",
          :video_codec  => { :codec => 'h264' },
          :audio_codec  => 'acc',
          :start_offset => 3) }

      it 'should create a tag with "src" attribute that includes the transformations' do
        expect(test_tag["src"]).to include("ac_acc")
        expect(test_tag["src"]).to include("vc_h264")
        expect(test_tag["src"]).to include("so_3")
      end
    end

    describe ":source_types" do
      context "when a single source type is provided" do
        let(:options) { basic_options.merge(:source_types => "mp4") }
        it "should create a video tag" do
          expect(test_tag.name).to eq("video")
          expect(test_tag.attributes).to include({ 'height' => "100px",
                                                   'width'  => "200px",
                                                   'src'    => "http://res.cloudinary.com/test123/video/upload/movie.mp4" })
        end
        it "should not have a `type` attribute" do
          expect(test_tag.attributes).not_to include("type")
        end
        it "should not have inner `source` tags" do
          expect(test_tag.children.map(&:name)).not_to include("source")
        end
      end

      context 'when provided with multiple source types' do
        let(:options) { basic_options.merge(:source_types => %w(mp4 webm ogv)) }
        it "should create a tag with multiple source tags" do
          expect(test_tag.children.length).to eq(3)
          expect(test_tag.children[0].name).to eq("source")
          expect(test_tag.children[1].name).to eq("source")
        end
        it "should order the source tags according to the order of the source_types" do
          expect(test_tag.children[0][:type]).to eq("video/mp4")
          expect(test_tag.children[1][:type]).to eq("video/webm")
          expect(test_tag.children[2][:type]).to eq("video/ogg")
        end
      end
    end

    describe ":poster" do
      context "when poster is not provided" do
        it "should default to jpg with the video transformation" do
          expect(test_tag[:poster]).to eq(cl_video_thumbnail_path("movie", { :format => 'jpg' }))
        end
      end

      context "when given a string" do
        let(:options) { basic_options.merge(:poster => TEST_IMAGE_URL) }
        it "should include a poster attribute with the given string as url" do
          expect(test_tag.attributes).to include('poster')
          expect(test_tag[:poster]).to eq(TEST_IMAGE_URL)
        end
      end

      context "when poster is a hash" do
        let(:options) { basic_options.merge(:poster => { :gravity => "north" }) }
        it "should include a poster attribute with the given options" do
          expect(test_tag[:poster]).to eq("http://res.cloudinary.com/test123/video/upload/g_north/movie.jpg")
        end
        context "when a public id is provided" do
          let(:options) { basic_options.merge(:poster => { :public_id => 'myposter.jpg', :gravity => "north" }) }
          it "should include a poster attribute with an image path and the given options" do
            expect(test_tag[:poster]).to eq("http://res.cloudinary.com/test123/image/upload/g_north/myposter.jpg")
          end


        end
      end

      context "when poster parameter is nil or false" do
        let(:options) { basic_options.merge(:poster => nil) }
        it "should not include a poster attribute in the tag for nil" do
          expect(test_tag.attributes).not_to include('poster')
        end
        let(:options) { basic_options.merge(:poster => false) }
        it "should not include a poster attribute in the tag for false" do
          expect(test_tag.attributes).not_to include('poster')
        end
      end
    end

    context ":source_transformation" do
      let(:options) { basic_options.merge(:source_types          => %w(mp4 webm),
                                          :source_transformation => { 'mp4'  => { 'quality' => 70 },
                                                                      'webm' => { 'quality' => 30 } }
      ) }
      it "should produce the specific transformation for each type" do
        expect(test_tag.children_by_type("video/mp4")[0][:src]).to include("q_70")
        expect(test_tag.children_by_type("video/webm")[0][:src]).to include("q_30")
      end

    end

    describe ':fallback_content' do
      context 'when given fallback_content parameter' do
        let(:fallback) { "<span id=\"spanid\">Cannot display video</span>" }
        let(:options) { basic_options.merge(:fallback_content => fallback) }
        it "should include fallback content in the tag" do
          expect(test_tag.children).to include(TestTag.new(fallback))
        end
      end

      context "when given a block" do
        let(:test_tag) do
          # Actual code being tested ----------------
          html = helper.cl_video_tag("movie", options) do
            "Cannot display video!"
          end
          # -----------------------------------
          TestTag.new(html)
        end
        it 'should treat the block return value as fallback content' do
          expect(test_tag.children).to include("Cannot display video!")
        end
      end
      describe "dimensions" do
        context "when `:crop => 'fit'`" do
          let(:options) { basic_options.merge(:crop => 'fit') }
          it "should not include a width and height attributes" do
            expect(test_tag.attributes.keys).not_to include("width", "height")
          end
        end
      end
    end
  end
end
