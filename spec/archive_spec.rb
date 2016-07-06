require 'spec_helper'
require 'cloudinary'
require 'rest_client'
require 'zip'

RSpec.shared_context 'archive' do

  before :all do
    Cloudinary::Uploader.upload(
      "http://res.cloudinary.com/demo/image/upload/sample.jpg",
      :public_id      => 'tag_samplebw',
      :tags           => [TEST_TAG, TIMESTAMP_TAG],
      :transformation => {
        :effect => :blackwhite
      }
    )
    Cloudinary::Uploader.upload(
      "http://res.cloudinary.com/demo/image/upload/sample.jpg",
      :public_id      => 'tag_sample',
      :tags           => [TEST_TAG, TIMESTAMP_TAG],
      :transformation => {
        :effect => :blackwhite
      }
    )
  end
  include_context "cleanup", TIMESTAMP_TAG
end

describe Cloudinary::Utils do
  include_context 'archive'

  describe '.generate_zip_download_url' do
    let(:options) { {} }
    let!(:archive_result) {
      Cloudinary::Utils.download_zip_url(
        {
          :target_public_id => 'gem_archive_test',
          :public_ids       => %w(tag_sample tag_samplebw),
          :target_tags      => [TEST_TAG, TIMESTAMP_TAG]
        }.merge(options))
    }

    describe 'public_ids' do
      it 'should generate a valid url' do
        expect(archive_result).not_to be_empty
      end
      it 'should include two files' do
        Zip::File.open_buffer(RestClient.get(archive_result)) do |zip_file|
          list = zip_file.glob('*').map(&:name)
          expect(list.length).to be(2)
          expect(list).to include('tag_sample.jpg', 'tag_samplebw.jpg')
        end
      end
    end
  end
end

describe Cloudinary::Uploader do
  include_context 'archive'

  let(:options) { {} }

  describe '.create_archive' do
    let!(:target_public_id) {
      "gem_test#{ rand(1000000)}"
    }
    let!(:archive_result) {
      Cloudinary::Uploader.create_archive(
        {
          :target_public_id => target_public_id,
          :public_ids       => %w(tag_sample tag_samplebw),
          :tags             => [TEST_TAG, TIMESTAMP_TAG]
        }.merge(options))
    }
    let(:options) { { :mode => :create } }
    it 'should return a Hash' do
      expect(archive_result).to be_a(Hash)
    end
    expected_keys = %w(
              resource_type
              type
              public_id
              version
              url
              secure_url
              created_at
              tags
              signature
              bytes
              etag
              resource_count
              file_count
            )
    it "should include keys: #{expected_keys.join(', ')}" do
      expect(archive_result.keys).to match_array(expected_keys)
    end
  end
  describe '.create_zip' do
    it 'should call create_archive with "zip" format' do
      expect(Cloudinary::Uploader).to receive(:create_archive).with({ :tags => TEST_TAG }, "zip")
      Cloudinary::Uploader.create_zip({ :tags => TEST_TAG })
    end
  end
end