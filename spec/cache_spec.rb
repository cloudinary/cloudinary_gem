require 'spec_helper'
require 'cloudinary'
require 'cloudinary/cache'
require 'rspec'
require 'active_support/cache'

PUBLIC_ID = TEST_TAG + '_cache_' + SUFFIX
KEY = "some_key" + SUFFIX
RBP_TRANS = {:angle => 45, :crop => "scale"}
RBP_FORMAT = "png"
RBP_VALUES = [206, 50]


describe 'Responsive cache' do

  before :all do

    unless defined? Rails and defined? Rails.cache
      module Rails
        class << self
          attr_accessor :cache
        end
        Rails.cache = ActiveSupport::Cache::FileStore.new("#{__dir__}/../tmp/cache")
      end
    end

    Cloudinary::config.use_cache = true
    Cloudinary::Cache.storage= Rails.cache
    @i=0
  end

  after :all do
    # Rails.cache.clear
  end

  def get_cache
    Rails.cache.fetch KEY do
      puts "fetching"
      @i = @i + 1
    end
  end
  it 'should cache breakpoints' do
    j = get_cache
    j = get_cache

    expect(j).to eql(1)
    expect(@i).to eql(1)
  end

  it 'should cache upload results' do
    result = Cloudinary::Uploader.upload(
      TEST_IMG,
      :tags => [TEST_TAG, TIMESTAMP_TAG],
      responsive_breakpoints: [
        {
          create_derived: false,
          transformation: {
            angle: 90
          },
          format: 'gif'
        },
        {
          create_derived: false,
          transformation: {angle: 45, crop: 'scale'},
          format: 'png'
        },
        {
          create_derived: false,
        }
      ]
    )
    expect(result["responsive_breakpoints"]).to_not be_nil
    expect(result["responsive_breakpoints"].length).to_not eql(0)
    result["responsive_breakpoints"].each do |bp|
      bp = Cloudinary::Cache.get(
        result["public_id"],
        {
          type: bp["type"],
          resource_type: bp["resource_type"],
          raw_transformation: bp["transformation"]})
      expect(bp).to_not be_nil
    end
  end
  describe Cloudinary::Uploader do
    let (:options) { {
      :tags => [TEST_TAG, TIMESTAMP_TAG],
        :use_cache => true,
      :responsive_breakpoints => [
        {
          :create_derived => false,
          :transformation => {
            :angle => 90
          },
          :format => 'gif'
        },
        {
          :create_derived => false,
          :transformation => RBP_TRANS,
          :format => RBP_FORMAT
        },
        {
          :create_derived => false
        }
      ]
    }}
    before :all do
    end

    it "Should save responsive breakpoints to cache after upload" do
      result = Cloudinary::Uploader.upload( TEST_IMG, options)
      cache_value = Cloudinary::Cache.get(result["public_id"], transformation: RBP_TRANS, format: RBP_FORMAT)

      expect(cache_value).to eql(RBP_VALUES)
    end
  end

end