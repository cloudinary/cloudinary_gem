require 'rspec'
require 'spec_helper'
require 'cloudinary'

include Cloudinary

describe Utils do

  it 'should parse integer range values' do
    expect(Utils.norm_range_value("200")).to eq( "200")
  end
  it "should parse float range values" do
    expect(Utils.norm_range_value("200.0")).to eq("200.0"), "parse a float"
  end
  it "should parse a percent range value" do
    expect(Utils.norm_range_value("20p")).to eq("20p")
  end
end