require 'spec_helper'
require 'cloudinary'

describe Cloudinary::Api do
  break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?
  include_context "cleanup", TIMESTAMP_TAG

  prefix = TEST_TAG + "_#{Time.now.to_i}"
  test_id_1 = "#{prefix}_1"
  test_id_2 = "#{prefix}_2"
  test_id_3 = "#{prefix}_3"
  before(:all) do

    @api = Cloudinary::Api
  end

  describe 'create_streaming_profile' do
    it "should create a streaming profile with representations" do
      result = @api.create_streaming_profile test_id_1, :representations =>
        [{:transformation => {:crop => 'scale', :width => "1200", :height => "1200", :bit_rate => "5m"}}]
      expect(result).not_to be_blank
    end
  end
end
