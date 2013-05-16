require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Utils do
  before(:each) do
    Cloudinary.config do
      |config|
      config.cloud_name = "test123"
      config.secure_distribution = nil
      config.private_cdn = false
      config.secure = false
      config.cname = nil
      config.cdn_subdomains = false
      config.api_key = "1234"
      config.api_secret = "1234"
    end
  end
  
  it "should use cloud_name from config" do    
    result = Cloudinary::Utils.cloudinary_url("test")
    result.should == "http://res.cloudinary.com/test123/image/upload/test" 
  end

  it "should allow overriding cloud_name in options" do
    options = {:cloud_name=>"test321"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test321/image/upload/test" 
  end
  
  it "should use default secure distribution if secure=true" do    
    options = {:secure=>true}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://cloudinary-a.akamaihd.net/test123/image/upload/test" 
  end

  it "should allow overriding secure distribution if secure=true" do    
    options = {:secure=>true, :secure_distribution=>"something.else.com"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://something.else.com/test123/image/upload/test" 
  end

  it "should take secure distribution from config if secure=true" do
    Cloudinary.config.secure_distribution = "config.secure.distribution.com"    
    options = {:secure=>true}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://config.secure.distribution.com/test123/image/upload/test" 
  end

  it "should default to akamai if secure is given with private_cdn and no secure_distribution" do
    options = {:secure=>true, :private_cdn=>true}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://cloudinary-a.akamaihd.net/test123/image/upload/test" 
  end

  it "should not add cloud_name if secure private_cdn and secure non akamai secure_distribution" do
    options = {:secure=>true, :private_cdn=>true, :secure_distribution=>"something.cloudfront.net"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://something.cloudfront.net/image/upload/test" 
  end

  it "should allow overriding private_cdn if private_cdn=true" do
    result = Cloudinary::Utils.cloudinary_url("test", :private_cdn => true)
    result.should == "http://test123-res.cloudinary.com/image/upload/test"
  end

  it "should allow overriding private_cdn if private_cdn=false" do
    Cloudinary.config.private_cdn = true
    result = Cloudinary::Utils.cloudinary_url("test", :private_cdn => false)
    result.should == "http://res.cloudinary.com/test123/image/upload/test"
  end

  it "should allow overriding cname if cname=example.com" do
    result = Cloudinary::Utils.cloudinary_url("test", :cname => "example.com")
    result.should == "http://example.com/test123/image/upload/test"
  end

  it "should allow overriding cname if cname=false" do
    Cloudinary.config.cname = "example.com"
    result = Cloudinary::Utils.cloudinary_url("test", :cname => nil)
    result.should == "http://res.cloudinary.com/test123/image/upload/test"
  end

  it "should use format from options" do    
    options = {:format=>:jpg}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/test.jpg" 
  end

  it "should use width and height from options only if crop is given" do
    options = {:width=>100, :height=>100}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    result.should == "http://res.cloudinary.com/test123/image/upload/test" 
    options.should == {:width=>100, :height=>100}
    options = {:width=>100, :height=>100, :crop=>:crop}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {:width=>100, :height=>100}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_crop,h_100,w_100/test" 
  end

  it "should not pass width and height to html in case of fit, lfill or limit crop" do
    options = {:width=>100, :height=>100, :crop=>:limit}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_limit,h_100,w_100/test" 
    options = {:width=>100, :height=>100, :crop=>:lfill}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_lfill,h_100,w_100/test" 
    options = {:width=>100, :height=>100, :crop=>:fit}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_fit,h_100,w_100/test" 
  end

  it "should not pass width and height to html in case angle was used" do
    options = {:width=>100, :height=>100, :crop=>:scale, :angle=>:auto}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/a_auto,c_scale,h_100,w_100/test" 
  end
    
  it "should use x, y, radius, prefix, gravity and quality from options" do    
    options = {:x=>1, :y=>2, :radius=>3, :gravity=>:center, :quality=>0.4, :prefix=>"a"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/g_center,p_a,q_0.4,r_3,x_1,y_2/test" 
  end
  
  it "should support named tranformation" do    
    options = {:transformation=>"blip"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/t_blip/test" 
  end

  it "should support array of named tranformations" do    
    options = {:transformation=>["blip", "blop"]}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/t_blip.blop/test" 
  end

  it "should support base tranformation" do    
    options = {:transformation=>{:x=>100, :y=>100, :crop=>:fill}, :crop=>:crop, :width=>100}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {:width=>100}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_fill,x_100,y_100/c_crop,w_100/test" 
  end

  it "should support array of base tranformations" do    
    options = {:transformation=>[{:x=>100, :y=>100, :width=>200, :crop=>:fill}, {:radius=>10}], :crop=>:crop, :width=>100}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {:width=>100}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_fill,w_200,x_100,y_100/r_10/c_crop,w_100/test" 
  end

  it "should support array of tranformations" do    
    options = [{:x=>100, :y=>100, :width=>200, :crop=>:fill}, {:radius=>10}]
    result = Cloudinary::Utils.generate_transformation_string(options)
    result.should == "c_fill,w_200,x_100,y_100/r_10" 
  end

  it "should not include empty tranformations" do    
    options = {:transformation=>[{}, {:x=>100, :y=>100, :crop=>:fill}, {}]}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_fill,x_100,y_100/test" 
  end

  it "should support size" do    
    options = {:size=>"10x10", :crop=>:crop}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {:width=>"10", :height=>"10"}
    result.should == "http://res.cloudinary.com/test123/image/upload/c_crop,h_10,w_10/test" 
  end

  it "should use type from options" do
    options = {:type=>:facebook}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/facebook/test" 
  end

  it "should use resource_type from options" do
    options = {:resource_type=>:raw}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/raw/upload/test" 
  end

  it "should ignore http links only if type is not given or is asset" do
    options = {:type=>nil}
    result = Cloudinary::Utils.cloudinary_url("http://test", options)
    options.should == {}
    result.should == "http://test" 
    options = {:type=>:asset}
    result = Cloudinary::Utils.cloudinary_url("http://test", options)
    options.should == {}
    result.should == "http://test" 
    options = {:type=>:fetch}
    result = Cloudinary::Utils.cloudinary_url("http://test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/fetch/http://test" 
  end

  it "should use allow absolute links to /images" do
    options = {}
    result = Cloudinary::Utils.cloudinary_url("/images/test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/test" 
  end 

  it "should use ignore absolute links not to /images" do
    options = {}
    result = Cloudinary::Utils.cloudinary_url("/js/test", options)
    options.should == {}
    result.should == "/js/test" 
  end 

  it "should escape fetch urls" do
    options = {:type=>:fetch}
    result = Cloudinary::Utils.cloudinary_url("http://blah.com/hello?a=b", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/fetch/http://blah.com/hello%3Fa%3Db" 
  end 

  it "should should escape http urls" do
    options = {:type=>:youtube}
    result = Cloudinary::Utils.cloudinary_url("http://www.youtube.com/watch?v=d9NF2edxy-M", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/youtube/http://www.youtube.com/watch%3Fv%3Dd9NF2edxy%2DM" 
  end 

  it "should support background" do
    options = {:background=>"red"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/b_red/test" 
    options = {:background=>"#112233"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/b_rgb:112233/test" 
  end
  
  it "should support default_image" do
    options = {:default_image=>"default"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/d_default/test" 
  end

  it "should support angle" do
    options = {:angle=>"55"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/a_55/test" 

    options = {:angle=>["auto", "55"]}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/a_auto.55/test" 
  end
  
  it "should support format for fetch urls" do
    options = {:format=>"jpg", :type=>:fetch}
    result = Cloudinary::Utils.cloudinary_url("http://cloudinary.com/images/logo.png", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/fetch/f_jpg/http://cloudinary.com/images/logo.png" 
  end
  
  it "should support effect" do
    options = {:effect=>"sepia"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/e_sepia/test" 
  end

  it "should support effect with hash param" do
    options = {:effect=>{"sepia"=>10}}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/e_sepia:10/test" 
  end

  it "should support effect with array param" do
    options = {:effect=>["sepia", 10]}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/e_sepia:10/test" 
  end

  {:overlay=>:l, :underlay=>:u}.each do |param, letter|
    it "should support #{param}" do
      options = {param=>"text:hello"}
      result = Cloudinary::Utils.cloudinary_url("test", options)
      options.should == {}
      result.should == "http://res.cloudinary.com/test123/image/upload/#{letter}_text:hello/test" 
    end
    
    it "should not pass width/height to html for #{param}" do
      options = {param=>"text:hello", :height=>100, :width=>100}
      result = Cloudinary::Utils.cloudinary_url("test", options)
      options.should == {}
      result.should == "http://res.cloudinary.com/test123/image/upload/h_100,#{letter}_text:hello,w_100/test" 
    end
  end

  it "should use ssl_detected if secure is not given as parameter and not set to true in configuration" do    
    options = {:ssl_detected=>true}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://cloudinary-a.akamaihd.net/test123/image/upload/test" 
  end 

  it "should use secure if given over ssl_detected and configuration" do    
    options = {:ssl_detected=>true, :secure=>false}
    Cloudinary.config.secure = true
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/test" 
  end 

  it "should use secure: true from configuration over ssl_detected" do    
    options = {:ssl_detected=>false}
    Cloudinary.config.secure = true
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "https://cloudinary-a.akamaihd.net/test123/image/upload/test" 
  end 

  it "should support extenal cname" do
    options = {:cname=>"hello.com"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://hello.com/test123/image/upload/test" 
  end

  it "should support extenal cname with cdn_subdomain on" do
    options = {:cname=>"hello.com", :cdn_subdomain=>true}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://a2.hello.com/test123/image/upload/test" 
  end
  
  it "should support string param" do
    options = {"effect"=>{"sepia"=>10}}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/e_sepia:10/test" 
  end
  
  it "should support border" do
    options = {"border"=>{:width=>5}}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/bo_5px_solid_black/test"     
    options = {"border"=>{:width=>5, :color=>"#ffaabbdd"}}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/bo_5px_solid_rgb:ffaabbdd/test"     
    options = {"border"=>"1px_solid_blue"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/bo_1px_solid_blue/test"     
    options = {"border"=>"2"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {:border=>"2"}
    result.should == "http://res.cloudinary.com/test123/image/upload/test"     
  end
  
  it "should support flags" do
    options = {"flags"=>"abc"}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/fl_abc/test"     
    options = {"flags"=>["abc", "def"]}
    result = Cloudinary::Utils.cloudinary_url("test", options)
    options.should == {}
    result.should == "http://res.cloudinary.com/test123/image/upload/fl_abc.def/test"     
  end

  it "build_upload_params should not destroy options" do
    options = {:width=>100, :crop=>:scale}
    Cloudinary::Uploader.build_upload_params(options)[:transformation].should == "c_scale,w_100"
    options.length.should == 2
  end

  it "build_upload_params canonize booleans" do
    options = {:backup=>true, :use_filename=>false, :colors=>"true", :exif=>"false", :colors=>:true, 
               :image_metadata=>:false, :invalidate=>1, :eager_async=>"1"}
    params = Cloudinary::Uploader.build_upload_params(options)
    Cloudinary::Api.only(params, *options.keys).should == {
      :backup=>1, :use_filename=>0, :colors=>1, :exif=>0, :colors=>1, 
               :image_metadata=>0, :invalidate=>1, :eager_async=>1
    }
    Cloudinary::Uploader.build_upload_params(:backup=>nil)[:backup].should be_nil
    Cloudinary::Uploader.build_upload_params({})[:backup].should be_nil
  end
  
  it "should add version if public_id contains /" do
    result = Cloudinary::Utils.cloudinary_url("folder/test")
    result.should == "http://res.cloudinary.com/test123/image/upload/v1/folder/test"         
    result = Cloudinary::Utils.cloudinary_url("folder/test", :version=>123)
    result.should == "http://res.cloudinary.com/test123/image/upload/v123/folder/test"         
  end

  it "should not add version if public_id contains version already" do
    result = Cloudinary::Utils.cloudinary_url("v1234/test")
    result.should == "http://res.cloudinary.com/test123/image/upload/v1234/test"         
  end

  it "should allow to shorted image/upload urls" do
    result = Cloudinary::Utils.cloudinary_url("test", :shorten=>true)
    result.should == "http://res.cloudinary.com/test123/iu/test"         
  end
  
  it "should allow to use folders in PreloadedFile" do
    signature = Cloudinary::Utils.api_sign_request({:public_id=>"folder/file", :version=>"1234"}, Cloudinary.config.api_secret)
    preloaded = Cloudinary::PreloadedFile.new("image/upload/v1234/folder/file.jpg#" + signature)
    preloaded.should be_valid
  end
end
