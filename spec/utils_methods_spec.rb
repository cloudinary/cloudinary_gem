require 'rspec'
require 'spec_helper'
require 'cloudinary'

include Cloudinary

describe Utils do

  it 'should parse integer range values' do
    expect(Utils.instance_eval {norm_range_value("200")}).to eq( "200")
  end
  it "should parse float range values" do
    expect(Utils.instance_eval {norm_range_value("200.0")}).to eq("200.0"), "parse a float"
  end
  it "should parse a percent range value" do
    expect(Utils.instance_eval {norm_range_value("20p")}).to eq("20p")
  end

  describe '.smart_escape' do
    it 'escapes empty spaces to %20' do
      expect(Utils.smart_escape(' ')).to eq('%20')
    end

    it 'escapes / to %252F' do
      expect(Utils.smart_escape('/')).to eq('%252F')
    end

    it 'escapes , to %252C' do
      expect(Utils.smart_escape(',')).to eq('%252C')
    end
  end
end