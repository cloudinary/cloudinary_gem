require 'spec_helper'
require 'cloudinary'
require 'rest_client'
require 'zip'

ARCHIVE_TAG = "archive_test_tag_#{rand}"

RSpec.shared_context 'archive' do
  before :all do
    Cloudinary::Uploader.upload(
      "http://res.cloudinary.com/demo/image/upload/sample.jpg",
      :public_id      => 'tag_samplebw',
      :tags           => [TEST_TAG, ARCHIVE_TAG],
      :transformation => {
        :effect => :blackwhite
      }
    )
    Cloudinary::Uploader.upload(
      "http://res.cloudinary.com/demo/image/upload/sample.jpg",
      :public_id      => 'tag_sample',
      :tags           => [TEST_TAG, ARCHIVE_TAG],
      :transformation => {
        :effect => :blackwhite
      }
    )
  end
  after :all do
    if ARGV.include? '--cl:cleanup'
      puts "Cleanup"
      Cloudinary::Api.delete_resources_by_tag TEST_TAG
    else
      puts "Not cleaning up!"
    end
  end
end

describe Cloudinary::Utils do
  include_context 'archive'

  describe '.generate_zip_download_url' do
    let(:options) { {} }
    let!(:archive_result) {
      Cloudinary::Utils.generate_zip_download_url(
        {
          :target_public_id => 'gem_archive_test',
          :public_ids       => %w(tag_sample tag_samplebw),
          :tags             => ARCHIVE_TAG
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
  let!(:archive_result) {
    Cloudinary::Uploader.generate_archive(#TODO use generate_archive options
      {
        :target_public_id => 'gem_archive_test',
        :public_ids       => %w(tag_sample tag_samplebw),
        :tags             => ARCHIVE_TAG
      }.merge(options))
  }

  describe '.generate_archive' do
    describe 'mode' do
      context 'create' do
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
      context 'download' do
        let(:options) { { :mode => :download } }
        it 'should return an archive file' do
          expect(archive_result["content_type"]).to eq("application/zip")
        end
        it 'should include the requested resources' do
          Zip::File.open_buffer(archive_result["data"]) do |zip_file|
            list = zip_file.glob('*').map(&:name)
            expect(list.length).to be(2)
            expect(list).to include('tag_sample.jpg', 'tag_samplebw.jpg')
          end
        end
      end
    end
  end
end