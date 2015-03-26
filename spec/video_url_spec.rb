require 'rspec'
require 'spec_helper'
require 'cloudinary'
require 'action_view'
require 'cloudinary/helper'
require 'action_view/test_case'

describe Cloudinary::Utils do
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
  let(:root_path) { "http://res.cloudinary.com/test123" }
  let(:upload_path) { "#{root_path}/video/upload" }

  describe "cloudinary_url" do
    context ":video_codec" do
      it 'should support a string value' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :video_codec => 'auto' }, "#{upload_path}/vc_auto/video_id", {})
      end
      it 'should support a hash value' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :video_codec => { :codec => 'h264', :profile => 'basic', :level => '3.1' } },
                            "#{upload_path}/vc_h264:basic:3.1/video_id", {})
      end
    end
    context ":audio_codec" do
      it 'should support a string value' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :audio_codec => 'acc' }, "#{upload_path}/ac_acc/video_id", {})
      end
    end
    context ":bit_rate" do
      it 'should support an integer value' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :bit_rate => 2048 }, "#{upload_path}/br_2048/video_id", {})
      end
      it 'should support "<integer>k" ' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :bit_rate => '44k' }, "#{upload_path}/br_44k/video_id", {})
      end
      it 'should support "<integer>m"' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :bit_rate => '1m' }, "#{upload_path}/br_1m/video_id", {})
      end
    end
    context ":audio_frequency" do
      it 'should support an integer value' do
        test_cloudinary_url("video_id", { :resource_type => 'video', :audio_frequency => 44100 }, "#{upload_path}/af_44100/video_id", {})
      end
    end
    context ":video_sampling" do
      it "should support an integer value" do
        test_cloudinary_url("video_id", { :resource_type => 'video', :video_sampling => 20 }, "#{upload_path}/vs_20/video_id", {})
      end
      it "should support an string value in the a form of \"<float>s\"" do
        test_cloudinary_url("video_id", { :resource_type => 'video', :video_sampling => "2.3s" }, "#{upload_path}/vs_2.3s/video_id", {})
      end
    end
    { :so => :start_offset, :eo => :end_offset, :du => :duration }.each do |short, long|
      context ":#{long}" do
        it "should support decimal seconds " do
          test_cloudinary_url("video_id", { :resource_type => 'video', long => 2.63 }, "#{upload_path}/#{short}_2.63/video_id", {})
          test_cloudinary_url("video_id", { :resource_type => 'video', long => '2.63' }, "#{upload_path}/#{short}_2.63/video_id", {})
        end
        it 'should support percents of the video length as "<number>p"' do
          test_cloudinary_url("video_id", { :resource_type => 'video', long => '35p' }, "#{upload_path}/#{short}_35p/video_id", {})
        end
        it 'should support percents of the video length as "<number>%"' do
          test_cloudinary_url("video_id", { :resource_type => 'video', long => '35%' }, "#{upload_path}/#{short}_35p/video_id", {})
        end
      end
    end

    describe ":offset" do
      let(:test_url) { Cloudinary::Utils.cloudinary_url("video_id", options) }
      [
        ['string range', 'so_2.66,eo_3.21', '2.66..3.21'],
        ['array', 'so_2.66,eo_3.21', [2.66, 3.21]],
        ['range of floats', 'so_2.66,eo_3.21', 2.66..3.21],
        ['array of % strings', 'so_35p,eo_70p', %w(35% 70%)],
        ['array of p strings', 'so_35p,eo_70p', %w(35p 70p)],
        ['array of float percent', 'so_35.5p,eo_70.5p', %w(35.5p 70.5p)]
      ].each do |test|
        name, url_param, range = test
        context "when provided with #{name} #{range}" do
          let(:options) { { :resource_type => 'video', :offset => range } }
          it "should produce a range transformation in the format of #{url_param}" do
            expect { test_url }.to change { options }.to({})
            transformation = /([^\/]*)\/video_id$/.match(test_url)[1]
            # we can't rely on the order of the parameters so we sort them before comparing
            expect(transformation.split(',').sort.reverse.join(',')).to eq(url_param)
          end
        end
      end
    end
    context "when given existing relevant parameters: :quality, :background, :crop, :width, :height, :gravity, :overlay" do

      { :overlay => :l, :underlay => :u }.each do |param, letter|
        it "should support #{param}" do
          test_cloudinary_url("test", { :resource_type => 'video', param => "text:hello" }, "#{upload_path}/#{letter}_text:hello/test", {})
        end

        it "should not pass width/height to html for #{param}" do
          test_cloudinary_url("test", { :resource_type => 'video', param => "text:hello", :height => 100, :width => 100 }, "#{upload_path}/h_100,#{letter}_text:hello,w_100/test", {})
        end
      end
      it "should produce the transformation string" do
        test_cloudinary_url("test", { :resource_type => 'video', :background => "#112233" }, "#{upload_path}/b_rgb:112233/test", {})
        test_cloudinary_url("test", { :resource_type => 'video',
                                      :x             => 1, :y => 2, :radius => 3,
                                      :gravity       => :center,
                                      :quality       => 0.4,
                                      :prefix        => "a" }, "#{upload_path}/g_center,p_a,q_0.4,r_3,x_1,y_2/test", {})

      end
    end
  end

end