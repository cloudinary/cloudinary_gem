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
    Cloudinary::Uploader.upload(
      "http://res.cloudinary.com/demo/image/upload/sample.jpg",
      :public_id      => 'tag_sample_raw.jpg',
      :resource_type  => 'raw',
      :tags           => [TEST_TAG, TIMESTAMP_TAG],
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
      if RUBY_VERSION > "2"
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

  describe "download_backedup_asset" do
    it "should return url with asset and version id" do
      download_backedup_asset_url = Cloudinary::Utils.download_backedup_asset("b71b23d9c89a81a254b88a91a9dad8cd", "0e493356d8a40b856c4863c026891a4e")

      expect(download_backedup_asset_url).to include("asset_id")
      expect(download_backedup_asset_url).to include("version_id")
    end
  end
end

describe Cloudinary::Uploader do
  include_context 'archive'

  let(:options) { {} }

  describe '.create_archive' do
    let!(:target_public_id) {
      "gem_test#{ SUFFIX}"
    }
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
    let!(:archive_result) {
      Cloudinary::Uploader.create_archive(
        {
          :target_public_id => target_public_id,
          :public_ids       => %w(tag_sample tag_samplebw),
          :tags             => [TEST_TAG, TIMESTAMP_TAG],
          :transformations   => [{width: 100, height: 100, crop: "fill"},{effect: "grayscale"}],
          :skip_transformation_name => true
        }.merge(options))
    }
    let(:options) { { :mode => :create } }
    it 'should return a Hash with suitable set of keys' do
      expect(archive_result).to be_a(Hash)
      expect(archive_result.keys).to include(*expected_keys)
    end
  end
  describe 'create archive based on raw resources and missing public IDs' do
    let!(:target_public_id) {
      "gem_test#{ SUFFIX}"
    }
    let!(:archive_result) {
      Cloudinary::Uploader.create_archive(
        {
          :target_public_id => target_public_id,
          :public_ids       => %w(tag_sample_raw.jpg non-wxisting-resource),
          :resource_type    => 'raw',
          :allow_missing    => true
        }.merge(options))
    }
    let(:options) { { :mode => :create } }
    it 'should skip missing public IDs and successfully generate the archive containing raw resources' do
      expect(archive_result).to be_a(Hash)
      expect(archive_result["resource_count"]).to equal(1)
    end
  end
  describe '.create_zip' do
    it 'should call create_archive with "zip" format' do
      expect(Cloudinary::Uploader).to receive(:create_archive).with({ :tags => TEST_TAG }, "zip")
      Cloudinary::Uploader.create_zip({ :tags => TEST_TAG })
    end
  end
  describe '.create_archive based on fully_qualified_public_ids' do
    it 'should allow you to generate an archive by specifying multiple resource_types' do
      test_ids = %W(image/upload/#{TEST_IMG} video/upload/#{TEST_VIDEO} raw/upload/#{TEST_RAW})
      expected = {
        [:payload, :fully_qualified_public_ids] => test_ids,
        [:url]                                  => %r"/auto/generate_archive$"
      }
      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))
      Cloudinary::Uploader.create_archive(
        {
          :resource_type              => :auto,
          :fully_qualified_public_ids => test_ids
        }
      )
    end
  end

  describe "download_folder" do
    it "should return url with resource_type image" do
      download_folder_url = Cloudinary::Utils.download_folder("samples/", { :resource_type => "image" })

      expect(download_folder_url).to include("image")
    end

    it "should return valid url" do
      download_folder_url = Cloudinary::Utils.download_folder("folder/")

      expect(download_folder_url).not_to be_empty
      expect(download_folder_url).to include("generate_archive")
    end

    it "should flatten folder" do
      download_folder_url = Cloudinary::Utils.download_folder("folder/", { :flatten_folders => true })

      expect(download_folder_url).to include("flatten_folders")
    end

    it "should expire_at folder" do
      download_folder_url = Cloudinary::Utils.download_folder("folder/", { :expires_at => Time.now.to_i + 60 })

      expect(download_folder_url).to include("expires_at")
    end

    it "should use original file_name of folder" do
      download_folder_url = Cloudinary::Utils.download_folder("folder/", { :use_original_filename => true })

      expect(download_folder_url).to include("use_original_filename")
    end
  end
end
