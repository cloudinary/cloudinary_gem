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
  describe 'Utils.generate_token' do
    config_backup = Cloudinary.config.clone
    before do
      Cloudinary.config.akamai_key = '00112233FF99'
    end
    after do
      Cloudinary.config.each_pair { |k, _| Cloudinary.config.delete_field(k) }
      Cloudinary.config(config_backup.to_h)
    end
    it "should generate an Akamai token with start_time and window" do
      token = Utils.generate_token start_time: 1111111111, acl: '/image/*', window: 300
      expect(token).to eq('__cld_token__=st=1111111111~exp=1111111411~acl=/image/*~hmac=0854e8b6b6a46471a80b2dc28c69bd352d977a67d031755cc6f3486c121b43af')
    end
    it "should generate an Akamai token with window" do
      first_exp = Time.new.getgm.to_i + 300
      # expiration is calculated automatically as now + window
      token = Utils.generate_token acl: '*', window: 300
      second_exp = Time.new.getgm.to_i + 300
      match = /exp=(\d+)/.match(token)
      expect(match[1]).to be_truthy
      expiration = match[1].to_i
      expect(expiration).to be_between(first_exp, second_exp)
      expect(Utils.generate_token acl: '*', end_time: expiration).to eq(token)
    end

    it "should accept a key" do
      expect(Utils.generate_token acl: '*', end_time: 10000000, key: '00aabbff')
          .to eq('__cld_token__=exp=10000000~acl=*~hmac=030eafb6b19e499659d699b3d43e7595e35e3c0060e8a71904b3b8c8759f4890')
    end
    it "should throw if no end_time or window is provided" do
      expect { Utils.generate_token acl: '*' }.to raise_error('Must provide either end_time or window')
    end
  end
end