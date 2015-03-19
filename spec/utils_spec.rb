require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Utils do
  before(:each) do
    Cloudinary.config do |config|
      config.cloud_name = "test123"
      config.secure_distribution = nil
      config.private_cdn = false
      config.secure = false
      config.cname = nil
      config.cdn_subdomain = false
      config.api_key = "1234"
      config.api_secret = "b"
    end
  end
  let(:root_path) { "http://res.cloudinary.com/test123" }
  let(:upload_path) { "#{root_path}/image/upload" }

  it "should use cloud_name from config" do
    test_cloudinary_url("test", {}, "#{upload_path}/test", {})
  end

  it "should allow overriding cloud_name in options" do
    test_cloudinary_url("test", {:cloud_name=>"test321"}, "http://res.cloudinary.com/test321/image/upload/test", {})
  end
  
  it "should use default secure distribution if secure=true" do    
    test_cloudinary_url("test", {:secure=>true}, "https://res.cloudinary.com/test123/image/upload/test", {})
  end

  it "should allow overriding secure distribution if secure=true" do    
    test_cloudinary_url("test", {:secure=>true, :secure_distribution=>"something.else.com"}, "https://something.else.com/test123/image/upload/test", {})
  end

  it "should take secure distribution from config if secure=true" do
    Cloudinary.config.secure_distribution = "config.secure.distribution.com"
    test_cloudinary_url("test", {:secure=>true}, "https://config.secure.distribution.com/test123/image/upload/test", {})
  end

  it "should default to akamai if secure is given with private_cdn and no secure_distribution" do
    test_cloudinary_url("test", {:secure=>true, :private_cdn=>true}, "https://test123-res.cloudinary.com/image/upload/test", {})
  end

  it "should not add cloud_name if secure private_cdn and secure non akamai secure_distribution" do
    test_cloudinary_url("test", {:secure=>true, :private_cdn=>true, :secure_distribution=>"something.cloudfront.net"}, "https://something.cloudfront.net/image/upload/test", {})
  end

  it "should allow overriding private_cdn if private_cdn=true" do
    test_cloudinary_url("test", {:private_cdn => true}, "http://test123-res.cloudinary.com/image/upload/test", {})
  end

  it "should allow overriding private_cdn if private_cdn=false" do
    Cloudinary.config.private_cdn = true
    test_cloudinary_url("test", { :private_cdn => false }, "#{upload_path}/test", {})
  end

  it "should allow overriding cname if cname=example.com" do
    test_cloudinary_url("test", {:cname => "example.com"}, "http://example.com/test123/image/upload/test", {})
  end

  it "should allow overriding cname if cname=false" do
    Cloudinary.config.cname = "example.com"
    test_cloudinary_url("test", { :cname => false }, "#{upload_path}/test", {})
  end

  it "should use format from options" do
    test_cloudinary_url("test", { :format => :jpg }, "#{upload_path}/test.jpg", {})
  end

  it "should disallow url_suffix in shared distribution" do
    expect{Cloudinary::Utils.cloudinary_url("test", {:url_suffix=>"hello"})}.to raise_error(CloudinaryException)
  end

  it "should disallow url_suffix in non upload types" do
    expect{Cloudinary::Utils.cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true, :type=>:facebook})}.to raise_error(CloudinaryException)
  end

  it "should disallow url_suffix with / or ." do
    expect{Cloudinary::Utils.cloudinary_url("test", {:url_suffix=>"hello/world", :private_cdn=>true})}.to raise_error(CloudinaryException)
    expect{Cloudinary::Utils.cloudinary_url("test", {:url_suffix=>"hello.world", :private_cdn=>true})}.to raise_error(CloudinaryException)
  end

  it "should support url_suffix for private_cdn" do    
    test_cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true}, "http://test123-res.cloudinary.com/images/test/hello", {})
    test_cloudinary_url("test", {:url_suffix=>"hello", :angle=>0, :private_cdn=>true}, "http://test123-res.cloudinary.com/images/a_0/test/hello", {})
  end

  it "should put format after url_suffix" do
    test_cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true, :format=>"jpg"}, "http://test123-res.cloudinary.com/images/test/hello.jpg", {})
  end

  it "should not sign the url_suffix" do
    expected_signture = Cloudinary::Utils.cloudinary_url("test", :format=>"jpg", :sign_url=>true).match(/s--[0-9A-Za-z_-]{8}--/).to_s
    test_cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true, :format=>"jpg", :sign_url=>true}, "http://test123-res.cloudinary.com/images/#{expected_signture}/test/hello.jpg", {})

    expected_signture = Cloudinary::Utils.cloudinary_url("test", :format=>"jpg", :angle=>0, :sign_url=>true).match(/s--[0-9A-Za-z_-]{8}--/).to_s
    test_cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true, :format=>"jpg", :angle=>0, :sign_url=>true}, "http://test123-res.cloudinary.com/images/#{expected_signture}/a_0/test/hello.jpg", {})
  end

  it "should support url_suffix for raw uploads" do    
    test_cloudinary_url("test", {:url_suffix=>"hello", :private_cdn=>true, :resource_type=>:raw}, "http://test123-res.cloudinary.com/files/test/hello", {})
  end

  describe 'root_path support' do

    it "should allow use_root_path in shared distribution" do
      # expect{Cloudinary::Utils.cloudinary_url("test", {:use_root_path=>true})}.to raise_error(CloudinaryException)
      test_cloudinary_url("test", { :use_root_path => true, :private_cdn => false }, "#{root_path}/test", {})
      test_cloudinary_url("test", { :use_root_path => true, :private_cdn => false, :angle => 0 }, "#{root_path}/a_0/test", {})
    end

    it "should support use_root_path for private_cdn" do
      test_cloudinary_url("test", {:use_root_path=>true, :private_cdn=>true}, "http://test123-res.cloudinary.com/test", {})
      test_cloudinary_url("test", {:use_root_path=>true, :private_cdn=>true, :angle=>0}, "http://test123-res.cloudinary.com/a_0/test", {})
    end

    it "should support use_root_path together with url_suffix for private_cdn" do
      test_cloudinary_url("test", {:use_root_path=>true, :url_suffix=>"hello", :private_cdn=>true}, "http://test123-res.cloudinary.com/test/hello", {})
    end

    it "should disallow use_root_path if not image/upload" do
      expect{Cloudinary::Utils.cloudinary_url("test", {:use_root_path=>true, :private_cdn=>true, :type=>:facebook})}.to raise_error(CloudinaryException)
      expect{Cloudinary::Utils.cloudinary_url("test", {:use_root_path=>true, :private_cdn=>true, :resource_type=>:raw})}.to raise_error(CloudinaryException)
    end

  end

  it "should use width and height from options only if crop is given" do
    test_cloudinary_url("test", { :width => 100, :height => 100 }, "#{upload_path}/test", { :width => 100, :height => 100 })
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :crop }, "#{upload_path}/c_crop,h_100,w_100/test", { :width => 100, :height => 100 })
  end

  it "should not pass width and height to html in case of fit, lfill or limit crop" do
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :limit }, "#{upload_path}/c_limit,h_100,w_100/test", {})
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :lfill }, "#{upload_path}/c_lfill,h_100,w_100/test", {})
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :fit }, "#{upload_path}/c_fit,h_100,w_100/test", {})
  end

  it "should not pass width and height to html in case angle was used" do
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :scale, :angle => :auto }, "#{upload_path}/a_auto,c_scale,h_100,w_100/test", {})
  end
    
  it "should use x, y, radius, prefix, gravity and quality from options" do
    test_cloudinary_url("test", { :x => 1, :y => 2, :radius => 3, :gravity => :center, :quality => 0.4, :prefix => "a" }, "#{upload_path}/g_center,p_a,q_0.4,r_3,x_1,y_2/test", {})
  end
  
  it "should support named tranformation" do
    test_cloudinary_url("test", { :transformation => "blip" }, "#{upload_path}/t_blip/test", {})
  end

  it "should support array of named tranformations" do
    test_cloudinary_url("test", { :transformation => ["blip", "blop"] }, "#{upload_path}/t_blip.blop/test", {})
  end

  it "should support base tranformation" do
    test_cloudinary_url("test", { :transformation => { :x => 100, :y => 100, :crop => :fill }, :crop => :crop, :width => 100 }, "#{upload_path}/c_fill,x_100,y_100/c_crop,w_100/test", { :width => 100 })
  end

  it "should support array of base tranformations" do
    test_cloudinary_url("test", { :transformation => [{ :x => 100, :y => 100, :width => 200, :crop => :fill }, { :radius => 10 }], :crop => :crop, :width => 100 }, "#{upload_path}/c_fill,w_200,x_100,y_100/r_10/c_crop,w_100/test", { :width => 100 })
  end

  it "should support array of tranformations" do    
    result = Cloudinary::Utils.generate_transformation_string([{:x=>100, :y=>100, :width=>200, :crop=>:fill}, {:radius=>10}])
    expect(result).to eq("c_fill,w_200,x_100,y_100/r_10")
  end

  it "should not include empty tranformations" do
    test_cloudinary_url("test", { :transformation => [{}, { :x => 100, :y => 100, :crop => :fill }, {}] }, "#{upload_path}/c_fill,x_100,y_100/test", {})
  end

  it "should support size" do
    test_cloudinary_url("test", { :size => "10x10", :crop => :crop }, "#{upload_path}/c_crop,h_10,w_10/test", { :width => "10", :height => "10" })
  end

  it "should use type from options" do
    test_cloudinary_url("test", { :type => :facebook }, "#{root_path}/image/facebook/test", {})
  end

  it "should use resource_type from options" do
    test_cloudinary_url("test", { :resource_type => :raw }, "#{root_path}/raw/upload/test", {})
  end

  it "should ignore http links only if type is not given or is asset" do
    test_cloudinary_url("http://test", {:type=>nil}, "http://test", {})
    test_cloudinary_url("http://test", {:type=>:asset}, "http://test", {})
    test_cloudinary_url("http://test", { :type => :fetch }, "#{root_path}/image/fetch/http://test", {})
  end

  it "should use allow absolute links to /images" do
    test_cloudinary_url("/images/test", {}, "#{upload_path}/test", {})
  end 

  it "should use ignore absolute links not to /images" do
    test_cloudinary_url("/js/test", {}, "/js/test", {})
  end 

  it "should escape fetch urls" do
    test_cloudinary_url("http://blah.com/hello?a=b", { :type => :fetch }, "#{root_path}/image/fetch/http://blah.com/hello%3Fa%3Db", {})
  end 

  it "should should escape http urls" do
    test_cloudinary_url("http://www.youtube.com/watch?v=d9NF2edxy-M", { :type => :youtube }, "#{root_path}/image/youtube/http://www.youtube.com/watch%3Fv%3Dd9NF2edxy-M", {})
  end 

  it "should support background" do
    test_cloudinary_url("test", { :background => "red" }, "#{upload_path}/b_red/test", {})
    test_cloudinary_url("test", { :background => "#112233" }, "#{upload_path}/b_rgb:112233/test", {})
  end
  
  it "should support default_image" do
    test_cloudinary_url("test", { :default_image => "default" }, "#{upload_path}/d_default/test", {})
  end

  it "should support angle" do
    test_cloudinary_url("test", { :angle => "55" }, "#{upload_path}/a_55/test", {})
    test_cloudinary_url("test", { :angle => ["auto", "55"] }, "#{upload_path}/a_auto.55/test", {})
  end
  
  it "should support format for fetch urls" do
    test_cloudinary_url("http://cloudinary.com/images/logo.png", { :format => "jpg", :type => :fetch }, "#{root_path}/image/fetch/f_jpg/http://cloudinary.com/images/logo.png", {})
  end
  
  it "should support effect" do
    test_cloudinary_url("test", { :effect => "sepia" }, "#{upload_path}/e_sepia/test", {})
  end

  it "should support effect with hash param" do
    test_cloudinary_url("test", { :effect => { "sepia" => 10 } }, "#{upload_path}/e_sepia:10/test", {})
  end

  it "should support effect with array param" do
    test_cloudinary_url("test", { :effect => ["sepia", 10] }, "#{upload_path}/e_sepia:10/test", {})
  end

  {:overlay=>:l, :underlay=>:u}.each do |param, letter|
    it "should support #{param}" do
      test_cloudinary_url("test", { param => "text:hello" }, "#{upload_path}/#{letter}_text:hello/test", {})
    end
    
    it "should not pass width/height to html for #{param}" do
      test_cloudinary_url("test", { param => "text:hello", :height => 100, :width => 100 }, "#{upload_path}/h_100,#{letter}_text:hello,w_100/test", {})
    end
  end


  it "should use ssl_detected if secure is not given as parameter and not set to true in configuration" do    
    test_cloudinary_url("test", {:ssl_detected=>true}, "https://res.cloudinary.com/test123/image/upload/test", {})
  end 

  it "should use secure if given over ssl_detected and configuration" do    
    Cloudinary.config.secure = true
    test_cloudinary_url("test", { :ssl_detected => true, :secure => false }, "#{upload_path}/test", {})
  end 

  it "should use secure: true from configuration over ssl_detected" do    
    Cloudinary.config.secure = true
    test_cloudinary_url("test", {:ssl_detected=>false}, "https://res.cloudinary.com/test123/image/upload/test", {})
  end 

  it "should support extenal cname" do
    test_cloudinary_url("test", {:cname=>"hello.com"}, "http://hello.com/test123/image/upload/test", {})
  end

  it "should support extenal cname with cdn_subdomain on" do
    test_cloudinary_url("test", {:cname=>"hello.com", :cdn_subdomain=>true}, "http://a2.hello.com/test123/image/upload/test", {})
  end
  
  it "should support cdn_subdomain with secure on if using shared_domain" do
    test_cloudinary_url("test", {:secure=>true, :cdn_subdomain=>true}, "https://res-2.cloudinary.com/test123/image/upload/test", {})
  end

  it "should support secure_cdn_subdomain false override with secure" do
    test_cloudinary_url("test", {:secure=>true, :cdn_subdomain=>true, :secure_cdn_subdomain=>false}, "https://res.cloudinary.com/test123/image/upload/test", {})
  end

  it "should support secure_cdn_subdomain true override with secure" do
    test_cloudinary_url("test", {:secure=>true, :cdn_subdomain=>true, :secure_cdn_subdomain=>true, :private_cdn=>true}, "https://test123-res-2.cloudinary.com/image/upload/test", {})
  end

  it "should support string param" do
    test_cloudinary_url("test", { "effect" => { "sepia" => 10 } }, "#{upload_path}/e_sepia:10/test", {})
  end
  
  it "should support border" do
    test_cloudinary_url("test", { "border" => { :width => 5 } }, "#{upload_path}/bo_5px_solid_black/test", {})
    test_cloudinary_url("test", { "border" => { :width => 5, :color => "#ffaabbdd" } }, "#{upload_path}/bo_5px_solid_rgb:ffaabbdd/test", {})
    test_cloudinary_url("test", { "border" => "1px_solid_blue" }, "#{upload_path}/bo_1px_solid_blue/test", {})
    test_cloudinary_url("test", { "border" => "2" }, "#{upload_path}/test", { :border => "2" })
  end
  
  it "should support flags" do
    test_cloudinary_url("test", { "flags" => "abc" }, "#{upload_path}/fl_abc/test", {})
    test_cloudinary_url("test", { "flags" => ["abc", "def"] }, "#{upload_path}/fl_abc.def/test", {})
  end

  it "build_upload_params should not destroy options" do
    options = {:width=>100, :crop=>:scale}
    expect(Cloudinary::Uploader.build_upload_params(options)[:transformation]).to eq("c_scale,w_100")
    expect(options.length).to eq(2)
  end

  it "build_upload_params canonize booleans" do
    options = {:backup=>true, :use_filename=>false, :colors=>"true", :exif=>"false", :colors=>:true, 
               :image_metadata=>:false, :invalidate=>1, :eager_async=>"1"}
    params = Cloudinary::Uploader.build_upload_params(options)
    expect(Cloudinary::Api.only(params, *options.keys)).to eq(
      :backup=>1, :use_filename=>0, :colors=>1, :exif=>0, :colors=>1, 
               :image_metadata=>0, :invalidate=>1, :eager_async=>1
    )
    expect(Cloudinary::Uploader.build_upload_params(:backup=>nil)[:backup]).to be_nil
    expect(Cloudinary::Uploader.build_upload_params({})[:backup]).to be_nil
  end
  
  it "should add version if public_id contains /" do
    test_cloudinary_url("folder/test", {}, "#{upload_path}/v1/folder/test", {})
    test_cloudinary_url("folder/test", { :version => 123 }, "#{upload_path}/v123/folder/test", {})
  end

  it "should not add version if public_id contains version already" do
    test_cloudinary_url("v1234/test", {}, "#{upload_path}/v1234/test", {})
  end

  it "should allow to shorted image/upload urls" do
    test_cloudinary_url("test", { :shorten => true }, "#{root_path}/iu/test", {})
  end
  
  it "should allow to use folders in PreloadedFile" do
    signature = Cloudinary::Utils.api_sign_request({:public_id=>"folder/file", :version=>"1234"}, Cloudinary.config.api_secret)
    preloaded = Cloudinary::PreloadedFile.new("image/upload/v1234/folder/file.jpg#" + signature)
    expect(preloaded).to be_valid
  end
  
  it "should escape public_ids" do
    [
      ["a b", "a%20b"],
      ["a+b", "a%2Bb"],
      ["a%20b", "a%20b"],
      ["a-b", "a-b"],
      ["a??b", "a%3F%3Fb"],
      ["parentheses(interject)", "parentheses%28interject%29"]
    ].each do
      |source, target|
      expect(Cloudinary::Utils.cloudinary_url(source)).to eq("#{upload_path}/#{target}")
    end      
  end
  
  it "should correctly sign URLs", :signed => true do
    test_cloudinary_url("image.jpg", { :version => 1234, :transformation => { :crop => "crop", :width => 10, :height => 20 }, :sign_url => true }, "#{upload_path}/s--Ai4Znfl3--/c_crop,h_20,w_10/v1234/image.jpg", {})
    test_cloudinary_url("image.jpg", { :version => 1234, :sign_url => true }, "#{upload_path}/s----SjmNDA--/v1234/image.jpg", {})
    test_cloudinary_url("image.jpg", { :transformation => { :crop => "crop", :width => 10, :height => 20 }, :sign_url => true }, "#{upload_path}/s--Ai4Znfl3--/c_crop,h_20,w_10/image.jpg", {})
    test_cloudinary_url("image.jpg", { :transformation => { :crop => "crop", :width => 10, :height => 20 }, :type => :authenticated, :sign_url => true }, "#{root_path}/image/authenticated/s--Ai4Znfl3--/c_crop,h_20,w_10/image.jpg", {})
    test_cloudinary_url("http://google.com/path/to/image.png", { :type => "fetch", :version => 1234, :sign_url => true }, "#{root_path}/image/fetch/s--hH_YcbiS--/v1234/http://google.com/path/to/image.png", {})
  end

  it "should correctly sign URLs in deprecated sign_version mode", :signed => true do
    test_cloudinary_url("image.jpg", { :version => 1234, :transformation => { :crop => "crop", :width => 10, :height => 20 }, :sign_url => true, :sign_version => true }, "#{upload_path}/s--MaRXzoEC--/c_crop,h_20,w_10/v1234/image.jpg", {})
    test_cloudinary_url("image.jpg", { :version => 1234, :sign_url => true, :sign_version => true }, "#{upload_path}/s--ZlgFLQcO--/v1234/image.jpg", {})
    test_cloudinary_url("image.jpg", { :transformation => { :crop => "crop", :width => 10, :height => 20 }, :sign_url => true, :sign_version => true }, "#{upload_path}/s--Ai4Znfl3--/c_crop,h_20,w_10/image.jpg", {})
    test_cloudinary_url("http://google.com/path/to/image.png", { :type => "fetch", :version => 1234, :sign_url => true, :sign_version => true }, "#{root_path}/image/fetch/s--_GAUclyB--/v1234/http://google.com/path/to/image.png", {})
  end
  
  it "should correctly sign_request" do
    params = Cloudinary::Utils.sign_request({:public_id=>"folder/file", :version=>"1234"})
    expect(params).to eq(:public_id=>"folder/file", :version=>"1234", :signature=>"7a3349cbb373e4812118d625047ede50b90e7b67", :api_key=>"1234")
  end

  it "should support responsive width" do
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :crop, :responsive_width => true }, "#{upload_path}/c_crop,h_100,w_100/c_limit,w_auto/test", { :responsive => true })
    Cloudinary.config.responsive_width_transformation = {:width => :auto, :crop => :pad}
    test_cloudinary_url("test", { :width => 100, :height => 100, :crop => :crop, :responsive_width => true }, "#{upload_path}/c_crop,h_100,w_100/c_pad,w_auto/test", { :responsive => true })
  end

  it "should correctly encode double arrays" do
    expect(Cloudinary::Utils.encode_double_array([1,2,3,4])).to eq("1,2,3,4")
    expect(Cloudinary::Utils.encode_double_array([[1,2,3,4],[5,6,7,8]])).to eq("1,2,3,4|5,6,7,8")
  end
end
