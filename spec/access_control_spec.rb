require 'rspec'
require 'cloudinary'
require 'spec_helper'
require 'time'

# Calculates days as seconds
def days(n)
  n * 3600 * 24
end

describe "Access Control" do
  before :each do
    Cloudinary.reset_config
  end
  let (:acl) {{
      :access_type => 'anonymous',
      :start => '2019-02-22 16:20:57 +0200',
      :end => '2019-03-22 00:00 +0200'
  }}
  let (:acl_2) {{
      :access_type => 'anonymous',
      :start => '2019-02-22 16:20:57Z',
      :end => '2019-03-22 00:00 +0200'
  }}
  let (:acl_string) {
    '{"access_type":"anonymous","start":"2019-02-22 16:20:57 +0200","end":"2019-03-22 00:00 +0200"}'
  }
  let (:options) {{
      :public_id => TIMESTAMP_TAG,
      :tags => [TEST_TAG, TIMESTAMP_TAG, 'access_control_test']
  }}
  let(:resource ){
    Cloudinary::Uploader.upload(
      TEST_IMG,
      options)
  }
  describe 'build_upload_params' do
    it "should accept a Hash value" do
      params = Cloudinary::Uploader.build_upload_params access_control: acl
      expect(params).to have_key(:access_control)
      expect(params[:access_control]).to be_a String
      expect(params[:access_control]).to match(/^\[.+\]$/)

    end
    it "should accept an array of Hash values" do
      params = Cloudinary::Uploader.build_upload_params access_control: [acl, acl_2]
      expect(params).to have_key(:access_control)
      expect(params[:access_control]).to be_a String
      expect(params[:access_control]).to match(/^\[.+\]$/)
      j = JSON.parse(params[:access_control])
      expect(j.length).to be(2)
      expect(j[0]["access_type"]).to eql(acl[:access_type])
      expect(j[0]["start"]).to eql(acl[:start])
      expect(j[0]["end"]).to eql(acl[:end])
    end
    it "should accept a JSON string" do
      params = Cloudinary::Uploader.build_upload_params access_control: acl_string
      expect(params).to have_key(:access_control)
      expect(params[:access_control]).to be_a String
      expect(params[:access_control]).to eql("[#{acl_string}]")
    end
  end

  describe 'upload' do
      break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?
      include_context "cleanup", TIMESTAMP_TAG

      it 'should allow the user to define ACL in the upload parameters' do
        options[:access_control] = [acl]
        expect(RestClient::Request).to receive(:execute).with(
            deep_hash_value( {[:payload, :access_control] => "[#{acl_string}]"})
        ).and_call_original
        expect(resource).to have_key('access_control')
        response_acl = resource["access_control"]
        expect(response_acl.length).to be(1)
        expect(response_acl[0]["access_type"]).to eq("anonymous")
        expect(Time.parse(response_acl[0]["start"])).to eq(Time.parse(acl[:start]))
        expect(Time.parse(response_acl[0]["end"])).to eq(Time.parse(acl[:end]))
      end
  end
  describe 'update' do
      break puts("Please setup environment for api test to run") if Cloudinary.config.api_secret.blank?
      include_context "cleanup", TIMESTAMP_TAG

      it 'should allow the user to define ACL in the update parameters' do
        resource # upload before setting the expect
        expect(RestClient::Request).to receive(:execute).with(
            deep_hash_value( {[:payload, :access_control] => "[#{acl_string}]"})
        ).and_call_original
        result = Cloudinary::Api.update(
            resource['public_id'],
            :tags => [TEST_TAG, TIMESTAMP_TAG, 'access_control_test'],
            :access_control => acl)
        expect(result).to have_key('access_control')
        response_acl = result["access_control"]
        expect(response_acl.length).to be(1)
        expect(response_acl[0]["access_type"]).to eq("anonymous")
        expect(Time.parse(response_acl[0]["start"])).to eq(Time.parse(acl[:start]))
        expect(Time.parse(response_acl[0]["end"])).to eq(Time.parse(acl[:end]))
      end
  end
end