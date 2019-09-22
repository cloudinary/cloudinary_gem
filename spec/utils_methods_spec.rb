require 'rspec'
require 'spec_helper'
require 'cloudinary'
include Cloudinary

describe Utils do

  let(:cloud_name) { Cloudinary.config.cloud_name }
  let(:root_path) { "http://res.cloudinary.com/#{cloud_name}" }

  it 'should parse integer range values' do
    expect(Utils.instance_eval { norm_range_value("200") }).to eq("200")
  end
  it "should parse float range values" do
    expect(Utils.instance_eval { norm_range_value("200.0") }).to eq("200.0"), "parse a float"
  end
  it "should parse a percent range value" do
    expect(Utils.instance_eval { norm_range_value("20p") }).to eq("20p")
  end
  describe "json_array_param" do
    let (:data) {{:one => 1, :two => 2, "three" => 3}}
    let (:data_s) {"{\"one\":1,\"two\":2,\"three\":3}"}
    let (:data2) {{:foo => "bar"}}
    let (:data2_s) {"{\"foo\":\"bar\"}"}
    it "should convert a hash to json array" do
      result = Utils.json_array_param(data)
      expect(result).to match(/^\[.+\]$/)
    end
    it "should convert an array of hash to json array" do
      result = Utils.json_array_param([data, data2])
      expect(result).to eql("[#{data_s},#{data2_s}]")
    end
    it "should convert a json string to json array string" do
      result = Utils.json_array_param(data_s)
      expect(result).to eql("[#{data_s}]")
    end
    it "should accept a JSON array string and return it" do
      result = Utils.json_array_param("[#{data_s},#{data2_s}]")
      expect(result).to eql("[#{data_s},#{data2_s}]")
    end
    it "should throw an error if input string is not valid json string" do
      expect{Utils.json_array_param("I'm not a JSON object!")}.to raise_error(JSON::ParserError)
    end
    it "should support a block" do
      hash = {:block => "works"}
      hash_s = '{"block":"works"}'
      result = Utils.json_array_param(data) do |array|
        array[0]['foo'] = 'foobar'
        array.push(hash)

      end
      expect(result).to include(hash_s)
      expect(result).to include('foobar')
    end
  end
  describe 'is_remote_url' do
    it 'should identify remote URLs correctly' do
      [
        "ftp://ftp.cloudinary.com/images/old_logo.png",
        "http://cloudinary.com/images/old_logo.png",
        "https://cloudinary.com/images/old_logo.png",
        "s3://s3-us-west-2.amazonaws.com/cloudinary/images/old_logo.png",
        "gs://cloudinary/images/old_logo.png",
        "data:image/gif;charset=utf8;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7",
        "data:image/gif;param1=value1;param2=value2;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
      ].each do |url|
        expect(Cloudinary::Utils.is_remote?(url)).to eq(true), url
      end
    end
  end
  describe "radius transformation" do
    it "should process the radius correctly when given valid values" do
      valid_radius_test_values = [
        [10, "r_10"],
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
          .to produce_url("#{root_path}/image/upload/#{expected}/test") .and empty_options
      end
    end
    it "should throw an error when the radius is given invalid values" do
      invalid_radius_test_values = [
        [],
        [10,20,30,40,50]
      ]
      invalid_radius_test_values.each do |options|
        expect{Cloudinary::Utils.cloudinary_url("test", {:transformation => {:radius => options}})}
          .to raise_error(CloudinaryException)
      end
    end
  end
end
