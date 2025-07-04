require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Utils do
  SIGNATURE_VERIFICATION_API_SECRET = "X7qLTrsES31MzxxkxPPA-pAGGfU"
  API_SIGN_REQUEST_TEST_SECRET      = "hdcixPpR2iKERPwqvH6sHdK9cyac"
  API_SIGN_REQUEST_CLOUD_NAME       = "dn6ot3ged"

  before :each do
    Cloudinary.reset_config
    Cloudinary.config do |config|
      # config.cloud_name = "demo"
      config.secure_distribution = nil
      config.private_cdn         = false
      config.cname               = nil
      config.cdn_subdomain       = false
      config.analytics           = false
    end
  end

  let(:cloud_name) { Cloudinary.config.cloud_name }
  let(:root_path) { "https://res.cloudinary.com/#{cloud_name}" }
  let(:upload_path) { "#{root_path}/image/upload" }

  it "should allow overriding cloud_name in options" do
    expect(["test", { :cloud_name => "test321" }])
      .to produce_url("https://res.cloudinary.com/test321/image/upload/test")
            .and empty_options
  end

  it "should use default secure distribution if secure=true" do
    expect(["test", { :secure => true }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should allow overriding secure distribution if secure=true" do
    expect(["test", { :secure => true, :secure_distribution => "something.else.com" }])
      .to produce_url("https://something.else.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should take secure distribution from config if secure=true" do
    Cloudinary.config.secure_distribution = "config.secure.distribution.com"
    expect(["test", { :secure => true }])
      .to produce_url("https://config.secure.distribution.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should default to akamai if secure is given with private_cdn and no secure_distribution" do
    expect(["test", { :secure => true, :private_cdn => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/image/upload/test")
            .and empty_options
  end

  it "should not add cloud_name if secure private_cdn and secure non akamai secure_distribution" do
    expect(["test", { :secure => true, :private_cdn => true, :secure_distribution => "something.cloudfront.net" }])
      .to produce_url("https://something.cloudfront.net/image/upload/test")
            .and empty_options
  end

  it "should allow overriding private_cdn if private_cdn=true" do
    expect(["test", { :private_cdn => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/image/upload/test")
            .and empty_options
  end

  it "should allow overriding private_cdn if private_cdn=false" do
    Cloudinary.config.private_cdn = true
    expect(["test", { :private_cdn => false }])
      .to produce_url("#{upload_path}/test")
            .and empty_options
  end

  it "should allow overriding cname if cname=example.com" do
    expect(["test", { :secure => false, :cname => "example.com" }])
      .to produce_url("http://example.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should allow overriding cname if cname=false" do
    Cloudinary.config.cname = "example.com"
    expect(["test", { :cname => false }])
      .to produce_url("#{upload_path}/test")
            .and empty_options
  end

  it "should use format from options" do
    expect(["test", { :format => :jpg }])
      .to produce_url("#{upload_path}/test.jpg")
            .and empty_options
  end

  it "should support url_suffix in shared distribution" do
    expect(["test", { :url_suffix => "hello" }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/images/test/hello")
            .and empty_options
    expect(["test", { :url_suffix => "hello", :angle => 0 }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/images/a_0/test/hello")
            .and empty_options
  end

  it "should disallow url_suffix in non upload types" do
    expect { Cloudinary::Utils.cloudinary_url("test", { :url_suffix => "hello", :private_cdn => true, :type => :facebook }) }.to raise_error(CloudinaryException)
  end

  it "should disallow url_suffix with / or ." do
    expect { Cloudinary::Utils.cloudinary_url("test", { :url_suffix => "hello/world", :private_cdn => true }) }.to raise_error(CloudinaryException)
    expect { Cloudinary::Utils.cloudinary_url("test", { :url_suffix => "hello.world", :private_cdn => true }) }.to raise_error(CloudinaryException)
  end

  it "should support url_suffix for private_cdn" do
    expect(["test", { :url_suffix => "hello", :private_cdn => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/images/test/hello")
            .and empty_options
    expect(["test", { :url_suffix => "hello", :angle => 0, :private_cdn => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/images/a_0/test/hello")
            .and empty_options
  end

  it "should put format after url_suffix" do
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :format => "jpg" }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/images/test/hello.jpg")
            .and empty_options
  end

  it "should sign a url" do
    expected = Cloudinary::Utils.cloudinary_url "some_public_id.jpg",
                                                :cloud_name => "test",
                                                :api_key    => "123456789012345",
                                                :api_secret => "AbcdEfghIjklmnopq1234567890",
                                                :type       => "authenticated",
                                                :sign_url   => true,
                                                :overlay    => "text:Helvetica_50:test+text"
    expect(expected).to eq("https://res.cloudinary.com/test/image/authenticated/s--j5Z1ILxd--/l_text:Helvetica_50:test+text/some_public_id.jpg")
  end

  it "should sign an URL using SHA1 and generate a short signature by default" do
    expected = Cloudinary::Utils.cloudinary_url "sample.jpg",
                                                :cloud_name => "test123",
                                                :api_key    => "a",
                                                :api_secret => "b",
                                                :sign_url   => true

    expect(expected).to eq("https://res.cloudinary.com/test123/image/upload/s--v2fTPYTu--/sample.jpg")
  end

  it "should sign an URL using SHA256 and generate a long signature when long_url_signature is true" do
    expected = Cloudinary::Utils.cloudinary_url "sample.jpg",
                                                :cloud_name         => "test123",
                                                :api_key            => "a",
                                                :api_secret         => "b",
                                                :sign_url           => true,
                                                :long_url_signature => true

    expect(expected).to eq("https://res.cloudinary.com/test123/image/upload/s--2hbrSMPOjj5BJ4xV7SgFbRDevFaQNUFf--/sample.jpg")
  end

  it "should sign url with SHA256 algorithm set in configuration" do
    Cloudinary.config.signature_algorithm = Cloudinary::Utils::ALGO_SHA256

    expected = Cloudinary::Utils.cloudinary_url "sample.jpg",
                                                :cloud_name => "test123",
                                                :api_key    => "a",
                                                :api_secret => "b",
                                                :sign_url   => true

    expect(expected).to eq("https://res.cloudinary.com/test123/image/upload/s--2hbrSMPO--/sample.jpg")
  end

  it "should not sign the url_suffix" do
    expected_signature = Cloudinary::Utils.cloudinary_url("test", :format => "jpg", :sign_url => true).match(/s--[0-9A-Za-z_-]{8}--/).to_s
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :format => "jpg", :sign_url => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/images/#{expected_signature}/test/hello.jpg")
            .and empty_options

    expected_signature = Cloudinary::Utils.cloudinary_url("test", :format => "jpg", :angle => 0, :sign_url => true).match(/s--[0-9A-Za-z_-]{8}--/).to_s
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :format => "jpg", :angle => 0, :sign_url => true }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/images/#{expected_signature}/a_0/test/hello.jpg")
            .and empty_options
  end

  it "should support url_suffix for raw uploads" do
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :resource_type => :raw }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/files/test/hello")
            .and empty_options
  end

  it "should support url_suffix for videos" do
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :resource_type => :video }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/videos/test/hello")
            .and empty_options
  end

  it "should support url_suffix for private images" do
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :resource_type => :image, :type => :private }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/private_images/test/hello")
            .and empty_options
    expect(["test", { :url_suffix => "hello", :private_cdn => true, :format => "jpg", :resource_type => :image, :type => :private }])
      .to produce_url("https://#{cloud_name}-res.cloudinary.com/private_images/test/hello.jpg")
            .and empty_options
  end

  it "should support url_suffix for authenticated images" do
    expect(["test", { :url_suffix => "hello", :format => "jpg", :resource_type => :image, :type => :authenticated }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/authenticated_images/test/hello.jpg")
            .and empty_options
  end

  describe 'root_path support' do

    it "should allow use_root_path in shared distribution" do
      # expect{Cloudinary::Utils.cloudinary_url("test", {:use_root_path=>true})}.to raise_error(CloudinaryException)
      expect(["test", { :use_root_path => true, :private_cdn => false }])
        .to produce_url("#{root_path}/test")
              .and empty_options
      expect(["test", { :use_root_path => true, :private_cdn => false, :angle => 0 }])
        .to produce_url("#{root_path}/a_0/test")
              .and empty_options
    end

    it "should support use_root_path for private_cdn" do
      expect(["test", { :use_root_path => true, :private_cdn => true }])
        .to produce_url("https://#{cloud_name}-res.cloudinary.com/test")
              .and empty_options
      expect(["test", { :use_root_path => true, :private_cdn => true, :angle => 0 }])
        .to produce_url("https://#{cloud_name}-res.cloudinary.com/a_0/test")
              .and empty_options
    end

    it "should support use_root_path together with url_suffix for private_cdn" do
      expect(["test", { :use_root_path => true, :url_suffix => "hello", :private_cdn => true }])
        .to produce_url("https://#{cloud_name}-res.cloudinary.com/test/hello")
              .and empty_options
    end

    it "should disallow use_root_path if not image/upload" do
      expect { Cloudinary::Utils.cloudinary_url("test", { :use_root_path => true, :private_cdn => true, :type => :facebook }) }.to raise_error(CloudinaryException)
      expect { Cloudinary::Utils.cloudinary_url("test", { :use_root_path => true, :private_cdn => true, :resource_type => :raw }) }.to raise_error(CloudinaryException)
    end

  end
  describe ":width, :height" do
    it "should use width and height from options only if crop is given" do
      expect(["test", { :width => 100, :height => 100 }])
        .to produce_url("#{upload_path}/test")
              .and mutate_options_to({ :width => 100, :height => 100 })
      expect(["test", { :width => 100, :height => 100, :crop => :crop }])
        .to produce_url("#{upload_path}/c_crop,h_100,w_100/test")
              .and mutate_options_to({ :width => 100, :height => 100 })
    end

    it "should not pass width and height to html in case of fit, lfill or limit crop" do
      expect(["test", { :width => 100, :height => 100, :crop => :limit }])
        .to produce_url("#{upload_path}/c_limit,h_100,w_100/test")
              .and empty_options
      expect(["test", { :width => 100, :height => 100, :crop => :lfill }])
        .to produce_url("#{upload_path}/c_lfill,h_100,w_100/test")
              .and empty_options
      expect(["test", { :width => 100, :height => 100, :crop => :fit }])
        .to produce_url("#{upload_path}/c_fit,h_100,w_100/test")
              .and empty_options
    end

    it "should not pass width and height to html in case angle was used" do
      expect(["test", { :width => 100, :height => 100, :crop => :scale, :angle => :auto }])
        .to produce_url("#{upload_path}/a_auto,c_scale,h_100,w_100/test")
              .and empty_options
    end
    it "should support size" do
      expect(["test", { :size => "10x10", :crop => :crop }])
        .to produce_url("#{upload_path}/c_crop,h_10,w_10/test")
              .and mutate_options_to({ :width => "10", :height => "10" })
    end
    it "should support auto width" do
      expect(["test", { :width => "auto:20", :crop => :fill }])
        .to produce_url("#{upload_path}/c_fill,w_auto:20/test")
      expect(["test", { :width => "auto:20:350", :crop => :fill }])
        .to produce_url("#{upload_path}/c_fill,w_auto:20:350/test")
      expect(["test", { :width => "auto:breakpoints", :crop => :fill }])
        .to produce_url("#{upload_path}/c_fill,w_auto:breakpoints/test")
      expect(["test", { :width => "auto:breakpoints_100_1900_20_15", :crop => :fill }])
        .to produce_url("#{upload_path}/c_fill,w_auto:breakpoints_100_1900_20_15/test")
      expect(["test", { :width => "auto:breakpoints:json", :crop => :fill }])
        .to produce_url("#{upload_path}/c_fill,w_auto:breakpoints:json/test")
    end
    it 'should support ih,iw' do
      expect(["test", { :width => "iw", :height => "ih", :crop => :crop }])
        .to produce_url("#{upload_path}/c_crop,h_ih,w_iw/test")
    end
  end

  it "should use x, y, radius, prefix, gravity and quality from options" do
    expect(["test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => 0.4, :prefix => "a" }])
      .to produce_url("#{upload_path}/g_center,p_a,q_0.4,r_3,x_1,y_2/test")
            .and empty_options

    expect(["test", { :width => 0.5, :crop => :crop, :gravity => :auto }])
      .to produce_url("#{upload_path}/c_crop,g_auto,w_0.5/test")
            .and empty_options
  end

  describe "gravity" do
    it "should support auto" do
      expect(["test", { width: 100, height: 100, crop: 'crop', gravity: 'auto' }])
        .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_crop,g_auto,h_100,w_100/test")
              .and mutate_options_to({ width: 100, height: 100 })
      expect(["test", { width: 100, height: 100, crop: 'crop', gravity: 'auto' }])
        .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_crop,g_auto,h_100,w_100/test")
              .and mutate_options_to({ width: 100, height: 100 })
    end
    it "should support focal gravity" do
      ["adv_face", "adv_faces", "adv_eyes", "face", "faces", "body", "no_faces"].each do |focal|
        expect(["test", { width: 100, height: 100, crop: 'crop', gravity: "auto:#{focal}" }])
          .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_crop,g_auto:#{focal},h_100,w_100/test")
                .and mutate_options_to({ width: 100, height: 100 })
      end
    end
    it "should support auto level with thumb cropping" do
      [0, 10, 100].each do |level|
        expect(["test", { width: 100, height: 100, crop: 'thumb', gravity: "auto:#{level}" }])
          .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_thumb,g_auto:#{level},h_100,w_100/test")
                .and mutate_options_to({ width: 100, height: 100 })
        expect(["test", { width: 100, height: 100, crop: 'thumb', gravity: "auto:adv_faces:#{level}" }])
          .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_thumb,g_auto:adv_faces:#{level},h_100,w_100/test")
                .and mutate_options_to({ width: 100, height: 100 })
      end
    end
    it "should support custom_no_override" do
      expect(["test", { width: 100, height: 100, crop: 'crop', gravity: "auto:custom_no_override" }])
        .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/c_crop,g_auto:custom_no_override,h_100,w_100/test")
              .and mutate_options_to({ width: 100, height: 100 })
    end
  end

  describe ":quality" do
    it "support a percent value" do
      expect(["test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => 80, :prefix => "a" }])
        .to produce_url("#{upload_path}/g_center,p_a,q_80,r_3,x_1,y_2/test")

      expect(["test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => "80:444", :prefix => "a" }])
        .to produce_url("#{upload_path}/g_center,p_a,q_80:444,r_3,x_1,y_2/test")
    end
    it "should support auto value" do

      expect(["test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => "auto", :prefix => "a" }])
        .to produce_url("#{upload_path}/g_center,p_a,q_auto,r_3,x_1,y_2/test")

      expect(["test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => "auto:good", :prefix => "a" }])
        .to produce_url("#{upload_path}/g_center,p_a,q_auto:good,r_3,x_1,y_2/test")

    end
  end

  describe ":transformation" do
    it "should support named transformation" do
      expect(["test", { :transformation => "blip" }])
        .to produce_url("#{upload_path}/t_blip/test")
              .and empty_options
    end

    it "should support array of named transformation" do
      expect(["test", { :transformation => ["blip", "blop"] }])
        .to produce_url("#{upload_path}/t_blip.blop/test")
              .and empty_options
    end

    it "should support base transformation" do
      expect(["test", { :transformation => { :x => 100, :y => 100, :crop => :fill }, :crop => :crop, :width => 100 }])
        .to produce_url("#{upload_path}/c_fill,x_100,y_100/c_crop,w_100/test")
              .and mutate_options_to({ :width => 100 })
    end

    it "should support array of base transformation" do
      expect(["test", { :transformation => [{ :x => 100, :y => 100, :width => 200, :crop => :fill }, { :radius => 10 }], :crop => :crop, :width => 100 }])
        .to produce_url("#{upload_path}/c_fill,w_200,x_100,y_100/r_10/c_crop,w_100/test")
              .and mutate_options_to({ :width => 100 })
    end

    it "should support array of transformation" do
      result = Cloudinary::Utils.generate_transformation_string([{ :x => 100, :y => 100, :width => 200, :crop => :fill }, { :radius => 10 }])
      expect(result).to eq("c_fill,w_200,x_100,y_100/r_10")
    end

    it "should not include empty transformation" do
      expect(["test", { :transformation => [{}, { :x => 100, :y => 100, :crop => :fill }, {}] }])
        .to produce_url("#{upload_path}/c_fill,x_100,y_100/test")
              .and empty_options
    end

    describe "should support and translate arithmetic operators" do
      it "should support * / + - ^" do
        t              = [{ :width => 'initial_width * 2 / 3 ^ 2', :height => 'initial_height + 2 - 3', :crop => 'scale' }]
        expected_trans = "c_scale,h_ih_add_2_sub_3,w_iw_mul_2_div_3_pow_2"
        expect(Cloudinary::Utils.cloudinary_url('sample', :transformation => t)).to eq("#{upload_path}/#{expected_trans}/sample")
      end
    end

    describe "duration conditions" do
      it "should support duration" do
        t              = [{ :if => "duration > 30", :crop => "scale", :width => "100" }]
        expected_trans = "if_du_gt_30,c_scale,w_100"
        expect(Cloudinary::Utils.cloudinary_url('sample', :transformation => t)).to eq("#{upload_path}/#{expected_trans}/sample")
      end

      it "should support initial_duration" do
        t              = [{ :if => "initial_duration > 30", :crop => "scale", :width => "100" }]
        expected_trans = "if_idu_gt_30,c_scale,w_100"
        expect(Cloudinary::Utils.cloudinary_url('sample', :transformation => t)).to eq("#{upload_path}/#{expected_trans}/sample")
      end
    end
  end

  it "should use type from options" do
    expect(["test", { :type => :facebook }])
      .to produce_url("#{root_path}/image/facebook/test")
            .and empty_options
  end

  it "should use resource_type from options" do
    expect(["test", { :resource_type => :raw }])
      .to produce_url("#{root_path}/raw/upload/test")
            .and empty_options
  end

  it "should ignore http links only if type is not given or is asset" do
    expect(["https://test", { :type => nil }])
      .to produce_url("https://test")
            .and empty_options
    expect(["https://test", { :type => :asset }])
      .to produce_url("https://test")
            .and empty_options
    expect(["https://test", { :type => :fetch }])
      .to produce_url("#{root_path}/image/fetch/https://test")
            .and empty_options
  end

  it "should use allow absolute links to /images" do
    expect(["/images/test", {}])
      .to produce_url("#{upload_path}/test")
            .and empty_options
  end

  it "should use ignore absolute links not to /images" do
    expect(["/js/test", {}])
      .to produce_url("/js/test")
            .and empty_options
  end

  it "should escape fetch urls" do
    expect(["https://blah.com/hello?a=b", { :type => :fetch }])
      .to produce_url("#{root_path}/image/fetch/https://blah.com/hello%3Fa%3Db")
            .and empty_options
  end

  it "should should escape http urls" do
    expect(["https://www.youtube.com/watch?v=d9NF2edxy-M", { :type => :youtube }])
      .to produce_url("#{root_path}/image/youtube/https://www.youtube.com/watch%3Fv%3Dd9NF2edxy-M")
            .and empty_options
  end

  it "should support background" do
    expect(["test", { :background => "red" }])
      .to produce_url("#{upload_path}/b_red/test")
            .and empty_options
    expect(["test", { :background => "#112233" }])
      .to produce_url("#{upload_path}/b_rgb:112233/test")
            .and empty_options
  end

  it "should support default_image" do
    expect(["test", { :default_image => "default" }])
      .to produce_url("#{upload_path}/d_default/test")
            .and empty_options
  end

  it "should support angle" do
    expect(["test", { :angle => "55" }])
      .to produce_url("#{upload_path}/a_55/test")
            .and empty_options
    expect(["test", { :angle => ["auto", "55"] }])
      .to produce_url("#{upload_path}/a_auto.55/test")
            .and empty_options
  end

  it "should process the radius correctly when given valid values" do
    valid_radius_test_values = [
      [10, 'r_10'],
      ['10', 'r_10'],
      ['$v', 'r_$v'],
      [[10, 20, 30], 'r_10:20:30'],
      [[10, 20, '$v'], 'r_10:20:$v'],
      [[10, 20, '$v', 40], 'r_10:20:$v:40'],
      [['10:20'], 'r_10:20'],
      [['10:20:$v:40'], 'r_10:20:$v:40']
    ]
    valid_radius_test_values.each do |options, expected|
      expect(["test", { :transformation => { :radius => options } }])
        .to produce_url("#{root_path}/image/upload/#{expected}/test").and empty_options
    end
  end

  it "should throw an error when the radius is given invalid values" do
    invalid_radius_test_values = [
      [],
      [10, 20, 30, 40, 50]
    ]
    invalid_radius_test_values.each do |options|
      expect { Cloudinary::Utils.cloudinary_url("test", { :transformation => { :radius => options } }) }
        .to raise_error(CloudinaryException)
    end
  end

  it "should support format for fetch urls" do
    expect(["https://cloudinary.com/images/logo.png", { :format => "jpg", :type => :fetch }])
      .to produce_url("#{root_path}/image/fetch/f_jpg/https://cloudinary.com/images/logo.png")
            .and empty_options
  end

  it "should support effect" do
    expect(["test", { :effect => "sepia" }])
      .to produce_url("#{upload_path}/e_sepia/test")
            .and empty_options
  end

  it "should support effect with hash param" do
    expect(["test", { :effect => { "sepia" => -10 } }])
      .to produce_url("#{upload_path}/e_sepia:-10/test")
            .and empty_options
  end

  it "should support effect with array param" do
    expect(["test", { :effect => ["sepia", 10] }])
      .to produce_url("#{upload_path}/e_sepia:10/test")
            .and empty_options
  end

  it "should support blur effect with ocr gravity" do
    expect(["test", { :effect => ["blur_region", 5000], :gravity => "ocr_text" }])
      .to produce_url("#{upload_path}/e_blur_region:5000,g_ocr_text/test")
            .and empty_options
  end

  it "should support artistic effect" do
    expect(["test", { :effect => "art:incognito" }])
      .to produce_url("#{upload_path}/e_art:incognito/test")
            .and empty_options
  end

  it "should support keyframe_interval" do
    expect(["test", { :keyframe_interval => 10 }])
      .to produce_url("#{upload_path}/ki_10/test")
            .and empty_options
  end

  it "should support streaming_profile" do
    expect(["test", { :streaming_profile => "some-profile" }])
      .to produce_url("#{upload_path}/sp_some-profile/test")
            .and empty_options
  end

  shared_examples "a signed url" do |specific_options = {}, specific_transformation = ""|
    let(:expected_transformation) do
      (specific_transformation.blank? || specific_transformation.match(/\/$/)) ? specific_transformation : "#{specific_transformation}/"
    end
    let!(:authenticated_image) do
      Cloudinary::Uploader.upload "https://res.cloudinary.com/demo/image/upload/sample.jpg",
                                  :type => 'authenticated',
                                  :tags => TEST_TAG
    end
    let(:options) { { :version => authenticated_image['version'], :sign_url => true, :type => :authenticated }.merge(specific_options) }
    let(:authenticated_path) { "#{root_path}/image/authenticated" }

    it "should correctly sign URL with version" do
      expect(["#{authenticated_image['public_id']}.jpg", options])
        .to produce_url(%r"#{authenticated_path}/s--[\w-]+--/#{expected_transformation}v#{authenticated_image['version']}/#{authenticated_image['public_id']}.jpg")
              .and empty_options
    end
    it "should correctly sign URL with transformation and version" do
      options[:transformation] = { :crop => "crop", :width => 10, :height => 20 }
      expect(["#{authenticated_image['public_id']}.jpg", options])
        .to produce_url(%r"#{authenticated_path}/s--[\w-]+--/c_crop,h_20,w_10/#{expected_transformation}v#{authenticated_image['version']}/#{authenticated_image['public_id']}.jpg")
              .and empty_options
    end
    it "should correctly sign URL with transformation" do
      options[:transformation] = { :crop => "crop", :width => 10, :height => 20 }
      expect(["#{authenticated_image['public_id']}.jpg", options])
        .to produce_url(%r"#{authenticated_path}/s--[\w-]+--/c_crop,h_20,w_10/#{expected_transformation}v#{authenticated_image['version']}/#{authenticated_image['public_id']}.jpg")
              .and empty_options
                     .and be_served_by_cloudinary
    end
    it "should correctly sign fetch URL" do
      options[:type] = :fetch
      expect(["https://res.cloudinary.com/demo/sample.png", options])
        .to produce_url(%r"^#{root_path}/image/fetch/s--[\w-]+--/#{expected_transformation}v#{authenticated_image['version']}/https://res.cloudinary.com/demo/sample.png$")
              .and empty_options
    end
  end

  { 'overlay' => :l, :underlay => :u }.each do |param, letter|
    describe param do
      let(:root_path) { "https://res.cloudinary.com/#{cloud_name}" }
      let(:layers_options) { [
        # [name,                    options,                                              result]
        ["string", "text:hello", "text:hello"],
        ["public_id", { "public_id" => "logo" }, "logo"],
        ["public_id with folder", { "public_id" => "folder/logo" }, "folder:logo"],
        ["private", { "public_id" => "logo", "type" => "private" }, "private:logo"],
        ["format", { "public_id" => "logo", "format" => "png" }, "logo.png"],
        ["video", { "resource_type" => "video", "public_id" => "cat" }, "video:cat"],
        ["fetch", { "url" => "https://res.cloudinary.com/demologos/cloudinary_full_logo_white_small.png" },
         "fetch:aHR0cHM6Ly9yZXMuY2xvdWRpbmFyeS5jb20vZGVtb2xvZ29zL2Nsb3VkaW5hcnlfZnVsbF9sb2dvX3doaXRlX3NtYWxsLnBuZw=="],
      ] }
      it "should support #{param}" do
        layers_options.each do |name, options, result|
          expect(["test", { param => options }]).to produce_url("#{upload_path}/#{letter}_#{result}/test").and empty_options
        end
      end

      it "should not pass width/height to html for #{param}" do
        expect(["test", { param => "text:hello", :height => 100, :width => 100 }])
          .to produce_url("#{upload_path}/h_100,#{letter}_text:hello,w_100/test")
                .and empty_options
      end
    end
  end

  describe "text" do

    text_layer   = "Hello World, /Nice to meet you?"
    text_encoded = "Hello%20World%252C%20%252FNice%20to%20meet%20you%3F"

    before :all do
      Cloudinary::Uploader.text(text_layer, {
        :public_id   => "test_text",
        :overwrite   => true,
        :font_family => "Arial",
        :font_size   => "18",
        :tags        => TEST_TAG
      })
      srt = Tempfile.new(['test_subtitles', '.srt'])
      srt.write <<-END
      1
      00:00:10,500 --> 00:00:13,000
      Hello World, Nice to meet you?

      END
      srt.rewind
      Cloudinary::Uploader.upload srt, :public_id => 'subtitles.srt', :resource_type => 'raw', :overwrite => true, :tags => TEST_TAG
      srt.unlink
    end

    include_context "cleanup"

    { 'overlay' => 'l' }.each do |param, short|
      # 'underlay' => 'u' behaves the same as overlay
      describe param do
        let(:root_path) { "https://res.cloudinary.com/#{cloud_name}" }
        # [name, options, result]
        layers_options = [
          ["string", "text:test_text:hello", "text:test_text:hello"],
          ["explicit layer parameter", "text:test_text:#{text_encoded}", "text:test_text:#{text_encoded}"],
          ["text parameter", { :public_id => "test_text", :text => text_layer }, "text:test_text:#{text_encoded}"],
          ["text with font family and size parameters", { :text => text_layer, :font_family => "Arial", :font_size => "18" }, "text:Arial_18:#{text_encoded}"],
          ["text with text style parameter", { :text => text_layer, :font_family => "Arial", :font_size => "18", :font_weight => "bold", :font_style => "italic", :letter_spacing => 4, :line_spacing => 2 }, "text:Arial_18_bold_italic_letter_spacing_4_line_spacing_2:#{text_encoded}"],
          ["text with antialiasing and font hinting", { :text => "Hello World, Nice to meet you?", :font_family => "Arial", :font_size => "18", :font_antialiasing => "best", :font_hinting => "medium" }, "text:Arial_18_antialias_best_hinting_medium:Hello%20World%252C%20Nice%20to%20meet%20you%3F"],
          ["text with text style parameter (explicit)", "text:Arial_18_antialias_best_hinting_medium:Hello%20World%252C%20Nice%20to%20meet%20you%3F", "text:Arial_18_antialias_best_hinting_medium:Hello%20World%252C%20Nice%20to%20meet%20you%3F"],
          ["subtitles", { :resource_type => "subtitles", :public_id => "subtitles.srt" }, "subtitles:subtitles.srt"],
          ["subtitles with font family and size", { :resource_type => "subtitles", :public_id => "subtitles.srt", :font_family => "Arial", :font_size => "40" }, "subtitles:Arial_40:subtitles.srt"],
          ["image of type fetch", { :public_id => "https://res.cloudinary.com/demo/image/upload/ci", :type => "fetch" }, "fetch:aHR0cHM6Ly9yZXMuY2xvdWRpbmFyeS5jb20vZGVtby9pbWFnZS91cGxvYWQvY2k="]
        ]
        layers_options.each do |name, options, result|
          it "should support #{name}" do
            expect(["sample.jpg", { param => options }]).to produce_url("#{upload_path}/#{short}_#{result}/sample.jpg").and empty_options
            # expect("#{upload_path}/#{short}_#{result}/sample.jpg").to be_served_by_cloudinary
          end
          unless options.is_a? String || param == 'underlay'
            op        = Hash.new
            op[param] = options
            it_behaves_like "a signed url", op, "#{short}_#{result}"
          end
        end

        it "should not pass width/height to html for #{param}" do
          expect(["test", { param => "text:test_text", :height => 100, :width => 100 }])
            .to produce_url("#{upload_path}/h_100,#{short}_text:test_text,w_100/test")
                  .and empty_options

        end
      end
    end
  end

  it "should support text layer style identifier variables" do
    options = [
      "sample",
      {
        transformation: [
                          {
                            variables: [
                                         ["$style", "!Arial_12!"],
                                       ]
                          },
                          {
                            overlay: {
                              text:       "hello-world",
                              text_style: "$style"
                            }
                          }
                        ]
      }
    ]

    expect(options).to produce_url("#{upload_path}/$style_!Arial_12!/l_text:$style:hello-world/sample")
  end

  it "should support external cname" do
    expect(["test", { :secure => false, :cname => "hello.com" }])
      .to produce_url("http://hello.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should support external cname with cdn_subdomain on" do
    expect(["test", { :secure => false, :cname => "hello.com", :private_cdn => true, :cdn_subdomain => true }])
      .to produce_url("http://a2.hello.com/image/upload/test")
            .and empty_options
  end

  it "should support cdn_subdomain with secure on if using shared_domain" do
    expect(["test", { :cdn_subdomain => true }])
      .to produce_url("https://res-2.cloudinary.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should support secure_cdn_subdomain false override with secure" do
    expect(["test", { :cdn_subdomain => true, :secure_cdn_subdomain => false }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/test")
            .and empty_options
  end

  it "should support secure_cdn_subdomain true override with secure" do
    expect(["test", { :secure => true, :cdn_subdomain => true, :secure_cdn_subdomain => true, :private_cdn => true }])
      .to produce_url("https://#{cloud_name}-res-2.cloudinary.com/image/upload/test")
            .and empty_options
  end

  it "should support analytics" do
    expect(["test", { :analytics => true }])
      .to produce_url(/https:\/\/res.cloudinary.com\/#{cloud_name}\/image\/upload\/test\?_a=[\w]+/)
  end

  it "should not add analytics in case public id contains '?'" do
    expect(["test?a=b", { :analytics => true }])
      .to produce_url("https://res.cloudinary.com/#{cloud_name}/image/upload/test%3Fa%3Db")
  end

  it "should support string param" do
    expect(["test", { "effect" => { "sepia" => 10 } }])
      .to produce_url("#{upload_path}/e_sepia:10/test")
            .and empty_options
  end

  it "should support border" do
    expect(["test", { "border" => { :width => 5 } }])
      .to produce_url("#{upload_path}/bo_5px_solid_black/test")
            .and empty_options
    expect(["test", { "border" => { :width => 5, :color => "#ffaabbdd" } }])
      .to produce_url("#{upload_path}/bo_5px_solid_rgb:ffaabbdd/test")
            .and empty_options
    expect(["test", { "border" => "1px_solid_blue" }])
      .to produce_url("#{upload_path}/bo_1px_solid_blue/test")
            .and empty_options
    expect(["test", { "border" => "2" }]).to produce_url("#{upload_path}/test").and mutate_options_to({ :border => "2" })
  end

  it "should support flags" do
    expect(["test", { "flags" => "abc" }])
      .to produce_url("#{upload_path}/fl_abc/test")
            .and empty_options
    expect(["test", { "flags" => ["abc", "def"] }])
      .to produce_url("#{upload_path}/fl_abc.def/test")
            .and empty_options
  end

  it "should support aspect ratio" do
    expect(["test", { "aspect_ratio" => "1.0" }])
      .to produce_url("#{upload_path}/ar_1.0/test")
            .and empty_options
    expect(["test", { "aspect_ratio" => "3:2" }])
      .to produce_url("#{upload_path}/ar_3:2/test")
            .and empty_options
  end

  it "build_upload_params should not destroy options" do
    options = { :width => 100, :crop => :scale }
    expect(Cloudinary::Uploader.build_upload_params(options)[:transformation]).to eq("c_scale,w_100")
    expect(options.length).to eq(2)
  end

  it "build_upload_params canonize booleans" do
    options = { :backup         => true, :use_filename => false, :colors => :true,
                :image_metadata => :false, :media_metadata => true, :invalidate => 1,
                :visual_search  => true,
    }
    params  = Cloudinary::Uploader.build_upload_params(options)
    expect(Cloudinary::Api.only(params, *options.keys))
      .to eq(:backup         => 1,
             :use_filename   => 0,
             :colors         => 1,
             :image_metadata => 0,
             :media_metadata => 1,
             :invalidate     => 1,
             :visual_search  => 1,
          )
    options = { :colors => "true", :exif => "false", :eager_async => "1", :media_metadata => true }
    params  = Cloudinary::Uploader.build_upload_params(options)
    expect(Cloudinary::Api.only(params, *options.keys))
      .to eq(:exif => 0, :colors => 1, :eager_async => 1, :media_metadata => 1)
    expect(Cloudinary::Uploader.build_upload_params(:backup => nil)[:backup]).to be_nil
    expect(Cloudinary::Uploader.build_upload_params({})[:backup]).to be_nil
  end

  it "build_upload_params force booleans" do
    options = { :backup         => true, :use_filename => false, :colors => :true,
                :image_metadata => :false, :media_metadata => true, :invalidate => 1,
                :visual_search  => true,
    }
    params  = Cloudinary::Uploader.build_upload_params(options, true)
    expect(Cloudinary::Api.only(params, *options.keys))
      .to eq(:backup         => true,
             :use_filename   => false,
             :colors         => true,
             :image_metadata => false,
             :media_metadata => true,
             :invalidate     => true,
             :visual_search  => true,
             )
    options = { :colors => "true", :exif => "false", :eager_async => "1", :media_metadata => true }
    params  = Cloudinary::Uploader.build_upload_params(options, true)
    expect(Cloudinary::Api.only(params, *options.keys))
      .to eq(:exif => false, :colors => true, :eager_async => true, :media_metadata => true)
  end

  it "should add version if public_id contains /" do
    expect(["folder/test", {}])
      .to produce_url("#{upload_path}/v1/folder/test")
            .and empty_options
    expect(["folder/test", { :version => 123 }])
      .to produce_url("#{upload_path}/v123/folder/test")
            .and empty_options
  end

  it "should not add version if public_id contains version already" do
    expect(["v1234/test", {}])
      .to produce_url("#{upload_path}/v1234/test")
            .and empty_options
  end

  it "should default force_version to True if no value is given" do
    expect(["folder/test", {}])
      .to produce_url("#{upload_path}/v1/folder/test")
            .and empty_options
  end

  it "should exclude the version if resource is stored in a folder and force_version is False" do
    expect(["folder/test", { :force_version => false }])
      .to produce_url("#{upload_path}/folder/test")
            .and empty_options
  end

  it "should include the version if given explicitly regardless of force_verison (without folder)" do
    expect(["test", { :force_version => false, :version => 12345 }])
      .to produce_url("#{upload_path}/v12345/test")
            .and empty_options
  end

  it "should include the version if given explicitly regardless of force_verison (with folder)" do
    expect(["folder/test", { :force_version => false, :version => 12345 }])
      .to produce_url("#{upload_path}/v12345/folder/test")
            .and empty_options
  end

  it "should use the force_version option if set in the global config" do
    Cloudinary.config(:force_version => false)
    expect(["folder/test", {}])
      .to produce_url("#{upload_path}/folder/test")
            .and empty_options
  end

  it "should ignore the global force_version config if version is set explicitly in the options" do
    Cloudinary.config(:force_version => false)
    expect(["folder/test", { :version => 12345 }])
      .to produce_url("#{upload_path}/v12345/folder/test")
            .and empty_options
  end

  it "should override global config option if force_version is given within options" do
    Cloudinary.config(:force_version => false)
    expect(["folder/test", { :force_version => true }])
      .to produce_url("#{upload_path}/v1/folder/test")
            .and empty_options
  end

  it "should allow to shorted image/upload urls" do
    expect(["test", { :shorten => true }])
      .to produce_url("#{root_path}/iu/test")
            .and empty_options
  end



  it "should escape public_ids" do
    [
      ["a b", "a%20b"],
      ["a+b", "a%2Bb"],
      ["a+b+c", "a%2Bb%2Bc"],
      ["a%20b", "a%20b"],
      ["a-b", "a-b"],
      ["a??b", "a%3F%3Fb"],
      ["parentheses(interject)", "parentheses%28interject%29"]
    ].each do
    |source, target|
      expect(Cloudinary::Utils.cloudinary_url(source)).to eq("#{upload_path}/#{target}")
    end
  end

  describe ":sign_url" do
    it_behaves_like "a signed url"
  end

  it "should correctly sign_request" do
    params = Cloudinary::Utils.sign_request(
      {
        :public_id => "folder/file",
        :version   => "1234" },
      {
        :cloud_name => "demo",
        :api_key    => "1234",
        :api_secret => "b"
      }
    )
    expect(params).to include(:signature => "7a3349cbb373e4812118d625047ede50b90e7b67")
  end

  it "should support responsive width" do
    expect(["test", { :width => 100, :height => 100, :crop => :crop, :responsive_width => true }])
      .to produce_url("#{upload_path}/c_crop,h_100,w_100/c_limit,w_auto/test")
            .and mutate_options_to({ :responsive => true })
    Cloudinary.config.responsive_width_transformation = { :width => :auto, :crop => :pad }
    expect(["test", { :width => 100, :height => 100, :crop => :crop, :responsive_width => true }])
      .to produce_url("#{upload_path}/c_crop,h_100,w_100/c_pad,w_auto/test")
            .and mutate_options_to({ :responsive => true })
  end

  it "should correctly encode double arrays" do
    expect(Cloudinary::Utils.encode_double_array([1, 2, 3, 4])).to eq("1,2,3,4")
    expect(Cloudinary::Utils.encode_double_array([[1, 2, 3, 4], [5, 6, 7, 8]])).to eq("1,2,3,4|5,6,7,8")
  end

  it "should sign an API request using SHA1 by default" do
    signature = Cloudinary::Utils.api_sign_request({ :cloud_name => API_SIGN_REQUEST_CLOUD_NAME, :timestamp => 1568810420, :username => "user@cloudinary.com" }, API_SIGN_REQUEST_TEST_SECRET)
    expect(signature).to eq("14c00ba6d0dfdedbc86b316847d95b9e6cd46d94")
  end

  it "should sign an API request using SHA256" do
    Cloudinary.config.signature_algorithm = Cloudinary::Utils::ALGO_SHA256
    signature                             = Cloudinary::Utils.api_sign_request({ :cloud_name => API_SIGN_REQUEST_CLOUD_NAME, :timestamp => 1568810420, :username => "user@cloudinary.com" }, API_SIGN_REQUEST_TEST_SECRET)
    expect(signature).to eq("45ddaa4fa01f0c2826f32f669d2e4514faf275fe6df053f1a150e7beae58a3bd")
  end

  it "should sign an API request using SHA256 via parameter" do
    signature = Cloudinary::Utils.api_sign_request({ :cloud_name => API_SIGN_REQUEST_CLOUD_NAME, :timestamp => 1568810420, :username => "user@cloudinary.com" }, API_SIGN_REQUEST_TEST_SECRET, :sha256)
    expect(signature).to eq("45ddaa4fa01f0c2826f32f669d2e4514faf275fe6df053f1a150e7beae58a3bd")
  end

  it "should raise when unsupported algorithm is passed" do
    signature_algorithm = "unsupported_algorithm"

    expect { Cloudinary::Utils.api_sign_request({ :cloud_name => API_SIGN_REQUEST_CLOUD_NAME, :timestamp => 1568810420, :username => "user@cloudinary.com" }, API_SIGN_REQUEST_TEST_SECRET, signature_algorithm) }
      .to raise_error("Unsupported algorithm 'unsupported_algorithm'")
  end

  it "should prevent parameter smuggling via & characters in parameter values with signature version 2" do
    params_with_ampersand = {
      :cloud_name       => API_SIGN_REQUEST_CLOUD_NAME,
      :timestamp        => 1568810420,
      :notification_url => "https://fake.com/callback?a=1&tags=hello,world"
    }

    signature_v1_with_ampersand = Cloudinary::Utils.api_sign_request(params_with_ampersand, API_SIGN_REQUEST_TEST_SECRET, nil, 1)
    signature_v2_with_ampersand = Cloudinary::Utils.api_sign_request(params_with_ampersand, API_SIGN_REQUEST_TEST_SECRET, nil, 2)

    params_smuggled = {
      :cloud_name       => API_SIGN_REQUEST_CLOUD_NAME,
      :timestamp        => 1568810420,
      :notification_url => "https://fake.com/callback?a=1",
      :tags             => "hello,world"
    }

    signature_v1_smuggled = Cloudinary::Utils.api_sign_request(params_smuggled, API_SIGN_REQUEST_TEST_SECRET, nil, 1)
    signature_v2_smuggled = Cloudinary::Utils.api_sign_request(params_smuggled, API_SIGN_REQUEST_TEST_SECRET, nil, 2)

    # Version 1 is vulnerable to parameter smuggling
    expect(signature_v1_with_ampersand).to eq(signature_v1_smuggled)

    # Version 2 prevents parameter smuggling
    expect(signature_v2_with_ampersand).not_to eq(signature_v2_smuggled)

    expected_v2_signature = "4fdf465dd89451cc1ed8ec5b3e314e8a51695704"
    expect(signature_v2_with_ampersand).to eq(expected_v2_signature)

    expected_v2_smuggled_signature = "7b4e3a539ff1fa6e6700c41b3a2ee77586a025f9"
    expect(signature_v2_smuggled).to eq(expected_v2_smuggled_signature)
  end

  describe ":if" do
    describe 'with literal condition string' do
      it "should include the if parameter as the first component in the transformation string" do
        expect(["sample", { if: "w_lt_200", crop: "fill", height: 120, width: 80 }])
          .to produce_url("#{upload_path}/if_w_lt_200,c_fill,h_120,w_80/sample")
        expect(["sample", { crop: "fill", height: 120, if: "w_lt_200", width: 80 }])
          .to produce_url("#{upload_path}/if_w_lt_200,c_fill,h_120,w_80/sample")

      end
      it "should allow multiple conditions when chaining transformations " do
        expect(["sample", transformation: [{ if: "w_lt_200", crop: "fill", height: 120, width: 80 },
                                           { if: "w_gt_400", crop: "fit", width: 150, height: 150 },
                                           { effect: "sepia" }]])
          .to produce_url("#{upload_path}/if_w_lt_200,c_fill,h_120,w_80/if_w_gt_400,c_fit,h_150,w_150/e_sepia/sample")
      end
      it "should allow multiple tags condition" do
        expect(["sample", transformation: [{ if: "!tag1:tag2:tag3!_in_tags", crop: "fill", height: 120, width: 80 },
                                           { if: "else", crop: "fit", width: 150, height: 150 },
                                           { effect: "sepia" }]])
          .to produce_url("#{upload_path}/if_!tag1:tag2:tag3!_in_tags,c_fill,h_120,w_80/if_else,c_fit,h_150,w_150/e_sepia/sample")
      end

      describe "including spaces and operators" do
        it "should translate operators" do
          expect(["sample", { if: "w < 200", crop: "fill", height: 120, width: 80 }])
            .to produce_url("#{upload_path}/if_w_lt_200,c_fill,h_120,w_80/sample")
        end
      end

      describe "empty expression" do
        it "should not include dangling if parameter when empty value specified" do
          expect(["sample", { width: "100", crop: "crop", height: "", if: "" }])
            .to produce_url("#{upload_path}/c_crop,w_100/sample")
          expect(["sample", { width: "100", crop: "crop", height: "", if: nil }])
            .to produce_url("#{upload_path}/c_crop,w_100/sample")
        end
      end

      describe 'if end' do
        it "should include the if_end as the last parameter in its component" do
          expect(["sample", transformation: [{ if: "w_lt_200" },
                                             { crop: "fill", height: 120, width: 80, effect: "sharpen" },
                                             { effect: "brightness:50" },
                                             { effect: "shadow", color: "red" },
                                             { if: "end" }]])
            .to produce_url("#{upload_path}/if_w_lt_200/c_fill,e_sharpen,h_120,w_80/e_brightness:50/co_red,e_shadow/if_end/sample")
        end
        it "should support if_else with transformation parameters" do
          expect(["sample", transformation: [{ if: "w_lt_200", crop: "fill", height: 120, width: 80 },
                                             { if: "else", crop: "fill", height: 90, width: 100 }]])
            .to produce_url("#{upload_path}/if_w_lt_200,c_fill,h_120,w_80/if_else,c_fill,h_90,w_100/sample")
        end
        it "if_else should be without any transformation parameters" do
          expect(["sample", transformation: [{ if: "w_lt_200" },
                                             { crop: "fill", height: 120, width: 80 },
                                             { if: "else" },
                                             { crop: "fill", height: 90, width: 100 }]])
            .to produce_url("#{upload_path}/if_w_lt_200/c_fill,h_120,w_80/if_else/c_fill,h_90,w_100/sample")
        end
      end
      it "should support and translate operators:  '=', '!=', '<', '>', '<=', '>=', '&&', '||'" do

        all_operators =
          'if_' +
            'w_eq_0_and' +
            '_w_ne_0_or' +
            '_h_lt_0_and' +
            '_ar_gt_0_and' +
            '_pc_lte_0_and' +
            '_fc_gte_0' +
            ',e_grayscale'

        expect(["sample",
                :if     => "width = 0 && w != 0 || height < 0 and aspect_ratio > 0 and page_count <= 0 and face_count >= 0",
                :effect => "grayscale"])
          .to produce_url("#{upload_path}/#{all_operators}/sample")
      end
    end

    describe "variables" do
      it "array should define a set of variables" do
        options = {
          :if        => "face_count > 2",
          :variables => [["$z", 5], ["$foo", "$z * 2"]],
          :crop      => "scale", :width => "$foo * 200"
        }
        t       = Cloudinary::Utils.generate_transformation_string options
        expect(t).to eq("if_fc_gt_2,$z_5,$foo_$z_mul_2,c_scale,w_$foo_mul_200")
      end
      it "'$key' should define a variable" do
        options = { :transformation => [
          { "$foo" => 10 },
          { :if => "face_count > 2" },
          { :crop => "scale", :width => "$foo * 200 / face_count" },
          { :if => "end" }
        ] }
        t       = Cloudinary::Utils.generate_transformation_string options
        expect(t).to eq("$foo_10/if_fc_gt_2/c_scale,w_$foo_mul_200_div_fc/if_end")
      end
      it "should support text values" do
        expect(["sample", :effect => "$efname:100", "$efname" => "!blur!"]).to produce_url "#{upload_path}/$efname_!blur!,e_$efname:100/sample"

      end
      it "should support string interpolation" do
        expect(["sample", :crop => "scale", :overlay => { :text => "$(start)Hello $(name)$(ext), $(no ) $( no)$(end)", :font_family => "Arial", :font_size => "18" }]).to produce_url "#{upload_path}/c_scale,l_text:Arial_18:$(start)Hello%20$(name)$(ext)%252C%20%24%28no%20%29%20%24%28%20no%29$(end)/sample"

      end

      it "should not change variable names even if they are keywords" do
        options = { :transformation => [
          { "$width" => 10 },
          { :width => "$width + 10 + width" }
        ] }

        t = Cloudinary::Utils.generate_transformation_string options, true
        expect(t).to eq("$width_10/w_$width_add_10_add_w")
      end

      it "should not affect user variable names containing predefined names" do
        options = {
          :transformation => [
            { :variables => [["$aheight", 300], ["$mywidth", "100"]] },
            { :width => "3 + $mywidth * 3 + 4 / 2 * initialWidth * $mywidth", :height => "3 * initialHeight + $aheight" },
          ]
        }

        t = Cloudinary::Utils.generate_transformation_string options, true
        expect(t).to eq("$aheight_300,$mywidth_100/h_3_mul_ih_add_$aheight,w_3_add_$mywidth_mul_3_add_4_div_2_mul_iw_mul_$mywidth")
      end

      it "should use context value as user variables" do
        options = {
          :variables => [["$xpos", "ctx:!x_pos!_to_f"], ["$ypos", "ctx:!y_pos!_to_f"]],
          :crop      => "crop",
          :x         => "$xpos * w",
          :y         => "$ypos * h"
        }

        t = Cloudinary::Utils.generate_transformation_string options
        expect(t).to eq("$xpos_ctx:!x_pos!_to_f,$ypos_ctx:!y_pos!_to_f,c_crop,x_$xpos_mul_w,y_$ypos_mul_h")
      end
    end

    describe "expression normalization" do
      value            = "width * 2"
      normalized_value = "w_mul_2"

      normalized_params = %w[angle aspect_ratio dpr effect height opacity quality width x y end_offset start_offset zoom]
      normalized_params.each do |param|
        it "should normalize value in #{param}" do
          # c_scale needed to test h_ and w_ parameters that are ignored without crop mode
          result = Cloudinary::Utils.generate_transformation_string({ param => value, :crop => "scale" })
          expect(result).to include(normalized_value) and not include(value)
        end
      end

      non_normalized_params = %w[audio_codec audio_frequency border bit_rate color_space default_image delay density
                                 fetch_format custom_function fps gravity overlay prefix page underlay video_sampling
                                 streaming_profile keyframe_interval]
      non_normalized_params.each do |param|
        it "should not normalize value in #{param}" do
          result = Cloudinary::Utils.generate_transformation_string({ param => value })
          expect(result).to include(value) and not include(normalized_value)
        end
      end
    end

    it "should support start offset" do
      options = {
        :width        => 100,
        :start_offset => "idu - 5"
      }
      t = Cloudinary::Utils.generate_transformation_string options

      expect(t).to include("so_idu_sub_5")

      options = {
        :width        => 100,
        :start_offset => "$logotime"
      }
      t = Cloudinary::Utils.generate_transformation_string options
      expect(t).to include("so_$logotime")
    end

    it "should support end offset" do
      options = {
        :width      => 100,
        :end_offset => "idu - 5"
      }
      t = Cloudinary::Utils.generate_transformation_string options
      expect(t).to include("eo_idu_sub_5")

      options = {
        :width      => 100,
        :end_offset => "$logotime"
      }
      t = Cloudinary::Utils.generate_transformation_string options
      expect(t).to include("eo_$logotime")
    end

    describe "context" do
      it 'should escape pipe and backslash characters' do
        context = { "caption" => "different = caption", "alt2" => "alt|alternative" }
        result  = Cloudinary::Utils.encode_context(context)
        expect(result).to eq("caption=different \\= caption|alt2=alt\\|alternative")
                            .or eq("alt2=alt\\|alternative|caption=different \\= caption")

      end
      it 'should support symbols' do
        context = { :symbol_key => "string_value", "string_key" => :symbol_value }
        result  = Cloudinary::Utils.encode_context(context)
        expect(result).to eq("string_key=symbol_value|symbol_key=string_value")
                            .or eq("symbol_key=string_value|string_key=symbol_value")
      end
    end

    describe "customFunction" do
      custom_function_wasm     = {
        :function_type => 'wasm',
        :source        => 'blur.wasm'
      }
      custom_function_wasm_str = 'wasm:blur.wasm'

      custom_function_remote     = {
        :function_type => 'remote',
        :source        => 'https://df34ra4a.execute-api.us-west-2.amazonaws.com/default/cloudinaryFunction'
      }
      custom_function_remote_str = 'remote:aHR0cHM6Ly9kZjM0cmE0YS5leGVjdXRlLWFwaS51cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9kZWZhdWx0L2Nsb3VkaW5hcnlGdW5jdGlvbg=='

      it 'should accept a string value' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_function => custom_function_wasm_str
        expect(actual).to eq("fn_#{custom_function_wasm_str}")
      end
      it 'should accept a hash of options' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_function => custom_function_wasm
        expect(actual).to eq("fn_#{custom_function_wasm_str}")
      end
      it 'should base64 encoded URL for a remote function' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_function => custom_function_remote
        expect(actual).to eq("fn_#{custom_function_remote_str}")

      end

      it 'should accept a string value' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_pre_function => custom_function_wasm_str
        expect(actual).to eq("fn_pre:#{custom_function_wasm_str}")
      end
      it 'should accept a hash of options' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_pre_function => custom_function_wasm
        expect(actual).to eq("fn_pre:#{custom_function_wasm_str}")
      end
      it 'should base64 encoded URL for a remote function' do
        actual = Cloudinary::Utils.generate_transformation_string :custom_pre_function => custom_function_remote
        expect(actual).to eq("fn_pre:#{custom_function_remote_str}")

      end

    end
  end

  describe ".verify_api_response_signature" do
    let(:public_id) { 'tests/logo.png' }
    let(:test_version) { 1 }
    let(:api_response_signature_sha1) { '08d3107a5b2ad82e7d82c0b972218fbf20b5b1e0' }
    let(:api_response_signature_sha256) { 'cc69ae4ed73303fbf4a55f2ae5fc7e34ad3a5c387724bfcde447a2957cacdfea' }

    before do
      Cloudinary.config.update(:api_secret => SIGNATURE_VERIFICATION_API_SECRET)
    end

    it "should return true when signature is valid" do
      expect(
        Cloudinary::Utils.verify_api_response_signature(public_id, test_version, api_response_signature_sha1)
      ).to be true
    end

    it "should return false when signature is invalid" do
      expect(
        Cloudinary::Utils.verify_api_response_signature(public_id, test_version + 1, api_response_signature_sha1)
      ).to be false
    end

    it "should support sha256 signature algorithm" do
      expect(
        Cloudinary::Utils.verify_api_response_signature(
          public_id,
          test_version,
          api_response_signature_sha256,
          Cloudinary::Utils::ALGO_SHA256)
      ).to be true
    end

    it "should use signature version 1 (without parameter encoding) for backward compatibility" do
      public_id_with_ampersand = 'tests/logo&version=2'
      
      expected_signature_v1 = Cloudinary::Utils.api_sign_request(
        { :public_id => public_id_with_ampersand, :version => test_version },
        SIGNATURE_VERIFICATION_API_SECRET,
        nil,
        1
      )
      
      expected_signature_v2 = Cloudinary::Utils.api_sign_request(
        { :public_id => public_id_with_ampersand, :version => test_version },
        SIGNATURE_VERIFICATION_API_SECRET,
        nil,
        2
      )
      
      expect(expected_signature_v1).not_to eq(expected_signature_v2)
      
      # verify_api_response_signature should use version 1 for backward compatibility
      expect(
        Cloudinary::Utils.verify_api_response_signature(
          public_id_with_ampersand,
          test_version,
          expected_signature_v1
        )
      ).to be true
      
      expect(
        Cloudinary::Utils.verify_api_response_signature(
          public_id_with_ampersand,
          test_version,
          expected_signature_v2
        )
      ).to be false
    end
  end

  describe ".verify_notification_signature" do
    let(:signature_sha1) { 'dfe82de1d9083fe0b7ea68070649f9a15b8874da' }
    let(:signature_sha256) { 'd5497e1a206ad0ba29ad09a7c0c5f22e939682d15009c15ab3199f62fefbd14b' }
    let(:valid_for) { 60 }
    let(:valid_response_timestamp) { (Time.now - valid_for).to_i }
    let(:body) do
      '{"notification_type":"eager","eager":[{"transformation":"sp_full_hd/mp4","bytes":1055,' \
               '"url":"http://res.cloudinary.com/demo/video/upload/sp_full_hd/v1533125278/dog.mp4",' \
               '"secure_url":"https://res.cloudinary.com/demo/video/upload/sp_full_hd/v1533125278/dog.mp4"}],' \
               '"public_id":"dog","batch_id":"9b11fa058c61fa577f4ec516bf6ee756ac2aefef095af99aef1302142cc1694a"}'
    end
    let(:response_json) { expected_parameters.to_json }
    let(:unexpected_response_json) { unexpected_parameters.to_json }
    let(:mocked_now) { 1549533574 }

    before do
      allow(Time).to receive(:now).and_return(mocked_now)
      Cloudinary.config.update(:api_secret => SIGNATURE_VERIFICATION_API_SECRET)
    end

    it "should return true for matching and not expired signature" do
      expect(
        Cloudinary::Utils.verify_notification_signature(
          body,
          valid_response_timestamp,
          signature_sha1,
          valid_for
        )
      ).to be true
    end

    it "should return false for matching but expired signature" do
      expect(
        Cloudinary::Utils.verify_notification_signature(
          body,
          valid_response_timestamp,
          signature_sha1,
          valid_for - 1
        )
      ).to be false
    end

    it "should return false for non matching and not expired signature" do
      expect(
        Cloudinary::Utils.verify_notification_signature(
          body,
          valid_response_timestamp,
          "#{signature_sha1}chars"
        )
      ).to be false
    end

    it "should return false for non matching and expired signature" do
      expect(
        Cloudinary::Utils.verify_notification_signature(
          body,
          valid_response_timestamp,
          "#{signature_sha1}chars",
          valid_for - 1
        )
      ).to be false
    end

    it "should raise when body is not a string" do
      expect {
        Cloudinary::Utils.verify_notification_signature(
          1,
          valid_response_timestamp,
          signature_sha1,
          valid_for
        )
      }.to raise_error("Body should be of String type")
    end

    it "should raise when api secret is not provided" do
      Cloudinary.config.api_secret = nil

      expect {
        Cloudinary::Utils.verify_notification_signature(
          body,
          valid_response_timestamp,
          signature_sha1,
          valid_for
        )
      }.to raise_error("Must supply api_secret")
    end

    it "should support sha256 signature algorithm" do
      expect(
        Cloudinary::Utils.verify_notification_signature(
          "{}",
          0,
          signature_sha256,
          mocked_now,
          Cloudinary::Utils::ALGO_SHA256,
          :api_secret => "someApiSecret"
        )
      ).to be true
    end
  end

  it "should download a sprite" do
    sprite_test_tag = "sprite_tag#{SUFFIX}"
    url1            = "https://res.cloudinary.com/demo/image/upload/sample"
    url2            = "https://res.cloudinary.com/demo/image/upload/car"

    url_from_tag  = Cloudinary::Utils.download_generated_sprite(sprite_test_tag)
    url_from_urls = URI.decode_www_form_component(Cloudinary::Utils.download_generated_sprite(:urls => [url1, url2]))

    expect(url_from_tag).to start_with("https://api.cloudinary.com/v1_1/#{Cloudinary.config.cloud_name}/image/sprite")
    expect(url_from_urls).to start_with("https://api.cloudinary.com/v1_1/#{Cloudinary.config.cloud_name}/image/sprite")
    expect(url_from_urls).to include("urls[]=#{url1}")
    expect(url_from_urls).to include("urls[]=#{url2}")

    parameters = CGI::parse(url_from_tag)
    expect(parameters["tag"]).to eq([sprite_test_tag])
    expect(parameters["mode"]).to eq([Cloudinary::Utils::MODE_DOWNLOAD])
    expect(parameters["timestamp"]).not_to be_nil
    expect(parameters["signature"]).not_to be_nil

    parameters = CGI::parse(url_from_urls)
    expect(parameters["mode"]).to eq([Cloudinary::Utils::MODE_DOWNLOAD])
    expect(parameters["timestamp"]).not_to be_nil
    expect(parameters["signature"]).not_to be_nil
  end

  describe "Response signature verification fixes" do
    let(:public_id) { 'tests/logo.png' }
    let(:test_version) { 1234 }
    let(:test_api_secret) { SIGNATURE_VERIFICATION_API_SECRET }
    
    before do
      Cloudinary.config.update(:api_secret => test_api_secret)
    end

    describe "api_sign_request signature_version parameter support" do
      it "should support signature_version parameter in api_sign_request" do
        params = { :public_id => public_id, :version => test_version }
        
        signature_v1 = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, 1)
        signature_v2 = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, 2)
        
        expect(signature_v1).to be_a(String)
        expect(signature_v2).to be_a(String)
        expect(signature_v1).to eq(signature_v2) # No & in values, so should be the same
      end

      it "should use default signature_version from config" do
        Cloudinary.config.signature_version = 2
        params = { :public_id => public_id, :version => test_version }
        
        signature_with_nil = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, nil)
        signature_with_v2 = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, 2)
        
        expect(signature_with_nil).to eq(signature_with_v2)
      end

      it "should default to version 2 when no config is set" do
        Cloudinary.config.signature_version = nil
        params = { :public_id => public_id, :version => test_version }
        
        signature_with_nil = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, nil)
        signature_with_v2 = Cloudinary::Utils.api_sign_request(params, test_api_secret, nil, 2)
        
        expect(signature_with_nil).to eq(signature_with_v2)
      end
    end


  end

  it "should download multi" do
    multi_test_tag = "multi_test_tag_#{UNIQUE_TEST_ID}"
    url1           = "https://res.cloudinary.com/demo/image/upload/sample"
    url2           = "https://res.cloudinary.com/demo/image/upload/car"

    url_from_tag  = Cloudinary::Utils.download_multi(multi_test_tag)
    url_from_urls = URI.decode_www_form_component(Cloudinary::Utils.download_multi(:urls => [url1, url2]))

    expect(url_from_tag).to start_with("https://api.cloudinary.com/v1_1/#{Cloudinary.config.cloud_name}/image/multi")
    expect(url_from_urls).to start_with("https://api.cloudinary.com/v1_1/#{Cloudinary.config.cloud_name}/image/multi")
    expect(url_from_urls).to include("urls[]=#{url1}")
    expect(url_from_urls).to include("urls[]=#{url2}")

    parameters = CGI::parse(url_from_tag)
    expect(parameters["tag"]).to eq([multi_test_tag])
    expect(parameters["mode"]).to eq([Cloudinary::Utils::MODE_DOWNLOAD])
    expect(parameters["timestamp"]).not_to be_nil
    expect(parameters["signature"]).not_to be_nil

    parameters = CGI::parse(url_from_urls)
    expect(parameters["mode"]).to eq([Cloudinary::Utils::MODE_DOWNLOAD])
    expect(parameters["timestamp"]).not_to be_nil
    expect(parameters["signature"]).not_to be_nil
  end
end
