require 'rspec'
require 'spec_helper'
require 'cloudinary'

include Cloudinary

describe Utils do

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
end