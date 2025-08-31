require 'spec_helper'
require 'cloudinary'

# Add blank? method for testing
class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end unless method_defined?(:blank?)
end

class NilClass
  def blank?
    true
  end unless method_defined?(:blank?)
end

module CarrierWave
  module Storage
    class Abstract
      def initialize(uploader)
        @uploader = uploader
      end

      attr_accessor :uploader
    end
  end

  class SanitizedFile
    def self.sanitize_regexp
      /[^a-zA-Z0-9\.\-\+_]/
    end
  end

  module Uploader
    class Base
      attr_accessor :cache_storage

      def self.storage(storage_class)
        @storage_class = storage_class
      end

      def self.cache_storage
        @cache_storage
      end

      def self.cache_storage=(storage)
        @cache_storage = storage
      end

      def self.class_attribute(*attrs, **options)
        attrs.each do |attr|
          instance_variable_set("@#{attr}", nil)
          define_singleton_method attr do |value = nil|
            if value
              instance_variable_set("@#{attr}", value)
            else
              instance_variable_get("@#{attr}")
            end
          end
          define_method attr do
            self.class.send(attr)
          end
          define_method "#{attr}=" do |value|
            self.class.send(attr, value)
          end unless options[:instance_reader] == false
        end
      end

      def self.extend(mod)
        super
      end

      def self.processors
        @processors ||= []
      end

      def self.process(method_name)
        processors << [method_name.keys.first, method_name.values.first, nil]
      end

      def self.version_names
        []
      end

      def initialize
        # Mock initialization
      end

      def version_name
        nil
      end

      def versions
        OpenStruct.new(values: [])
      end

      def transformation
        {}
      end
    end
  end
end

RSpec.describe Cloudinary::CarrierWave do
  describe '#store!' do
    let(:column) { 'example_field' }
    let(:identifier) { 'identifier' }
    let(:model) { double(:model, _mounter: mount) }
    let(:mount) { double(:mount, serialization_column: column) }
    let(:uploader) { spy(:uploader, model: model, mounted_as: :example).tap { |u| u.extend(Cloudinary::CarrierWave) } }

    subject { uploader.store! }

    it 'triggers `#retrieve_from_store!` after `#store!` executed to populate @file and @identifier' do
      expect(model).to receive(:read_attribute).with(column).and_return(identifier)
      expect(uploader).to receive(:retrieve_from_store!).with(identifier)

      subject
    end
  end

  describe 'upload parameters' do
    class TestUploader < CarrierWave::Uploader::Base
      include Cloudinary::CarrierWave
      attr_accessor :enable_processing

      def initialize(model = nil, mounted_as = nil)
        super()
        @enable_processing = true
      end
    end

    let(:uploader) { TestUploader.new }

    describe '#upload_params class method' do
      before do
        # Reset processors between tests
        TestUploader.instance_variable_set(:@processors, [])
      end

      it 'allows setting upload parameters' do
        TestUploader.upload_params(use_filename: true, overwrite: false)
        instance = TestUploader.new
        expect(instance.upload_params).to eq(use_filename: true, overwrite: false)
      end

      it 'merges multiple upload_params calls' do
        TestUploader.upload_params(use_filename: true)
        TestUploader.upload_params(overwrite: false)
        instance = TestUploader.new
        expect(instance.upload_params).to eq(use_filename: true, overwrite: false)
      end

      it 'supports asset_folder parameter' do
        TestUploader.upload_params(asset_folder: 'my_project_assets')
        instance = TestUploader.new
        expect(instance.upload_params).to eq(asset_folder: 'my_project_assets')
      end

      it 'supports display_name parameter' do
        TestUploader.upload_params(display_name: 'Sample Upload Test')
        instance = TestUploader.new
        expect(instance.upload_params).to eq(display_name: 'Sample Upload Test')
      end

      it 'combines asset_folder and display_name with other parameters' do
        TestUploader.upload_params(asset_folder: 'ecommerce_project')
        TestUploader.upload_params(display_name: 'Product Image Upload')
        TestUploader.upload_params(use_filename: true)
        TestUploader.upload_params(unique_filename: false)
        instance = TestUploader.new
        expect(instance.upload_params).to eq(
          asset_folder: 'ecommerce_project',
          display_name: 'Product Image Upload',
          use_filename: true,
          unique_filename: false
        )
      end

      it 'supports complex upload parameters including metadata and context' do
        TestUploader.upload_params(
          asset_folder: 'demo_project',
          display_name: 'CarrierWave Upload Test',
          use_filename: true,
          unique_filename: false,
          overwrite: true,
          context: { category: 'product', source: 'admin_panel' },
          metadata: { uploaded_by: 'admin_user', department: 'marketing' }
        )
        instance = TestUploader.new
        expected_params = {
          asset_folder: 'demo_project',
          display_name: 'CarrierWave Upload Test',
          use_filename: true,
          unique_filename: false,
          overwrite: true,
          context: { category: 'product', source: 'admin_panel' },
          metadata: { uploaded_by: 'admin_user', department: 'marketing' }
        }
        expect(instance.upload_params).to eq(expected_params)
      end
    end

    describe '#upload_params instance method' do
      it 'returns empty hash when no upload params are set' do
        uploader_class = Class.new(CarrierWave::Uploader::Base) do
          include Cloudinary::CarrierWave
        end
        instance = uploader_class.new
        expect(instance.upload_params).to eq({})
      end

      it 'prevents use in versions' do
        TestUploader.instance_variable_set(:@processors, [])
        TestUploader.upload_params(quality: 'auto')
        instance = TestUploader.new
        allow(instance).to receive(:version_name).and_return('thumb')
        expect { instance.upload_params }.to raise_error(CloudinaryException, "upload_params cannot be used in versions.")
      end
    end
  end
end

RSpec.describe Cloudinary::PreloadedFile do
  let(:test_api_secret) { "X7qLTrsES31MzxxkxPPA-pAGGfU" }

  before do
    Cloudinary.config.update(:api_secret => test_api_secret)
  end

  describe "folder support" do
    it "should allow to use folders in PreloadedFile" do
      signature = Cloudinary::Utils.api_sign_request({ :public_id => "folder/file", :version => "1234" }, Cloudinary.config.api_secret)
      preloaded = Cloudinary::PreloadedFile.new("image/upload/v1234/folder/file.jpg#" + signature)
      expect(preloaded).to be_valid
      [
        [:filename, 'folder/file.jpg'],
        [:version, '1234'],
        [:public_id, 'folder/file'],
        [:signature, signature],
        [:resource_type, 'image'],
        [:type, 'upload'],
        [:format, 'jpg']
      ].each do |attr, value|
        expect(preloaded.send(attr)).to eq(value)
      end
    end
  end

  describe "signature verification" do
    let(:public_id) { 'tests/logo.png' }
    let(:test_version) { 1234 }

    it "should correctly verify signature with proper parameter order" do
      # PreloadedFile extracts public_id by removing the format extension
      # So if filename is "tests/logo.png", public_id becomes "tests/logo"
      filename_with_format = public_id
      public_id_without_format = "tests/logo"  # public_id without .png extension

      # Generate a valid signature using the public_id without extension
      # The version parsed from preloaded string will be a string, so we use string here too
      version_string = test_version.to_s
      expected_signature = Cloudinary::Utils.api_sign_request(
        { :public_id => public_id_without_format, :version => version_string },
        test_api_secret,
        nil,
        1 # verify_api_response_signature uses version 1
      )

      # Create a preloaded file string
      preloaded_string = "image/upload/v#{version_string}/#{filename_with_format}##{expected_signature}"
      preloaded_file = Cloudinary::PreloadedFile.new(preloaded_string)

      expect(preloaded_file).to be_valid
    end

    it "should fail verification with incorrect signature" do
      wrong_signature = "wrongsignature"
      preloaded_string = "image/upload/v#{test_version}/#{public_id}##{wrong_signature}"
      preloaded_file = Cloudinary::PreloadedFile.new(preloaded_string)

      expect(preloaded_file).not_to be_valid
    end

    it "should handle raw resource type correctly" do
      raw_filename = "document.pdf"
      version_string = test_version.to_s
      raw_signature = Cloudinary::Utils.api_sign_request(
        { :public_id => raw_filename, :version => version_string },
        test_api_secret,
        nil,
        1
      )

      preloaded_string = "raw/upload/v#{version_string}/#{raw_filename}##{raw_signature}"
      preloaded_file = Cloudinary::PreloadedFile.new(preloaded_string)

      expect(preloaded_file).to be_valid
      expect(preloaded_file.resource_type).to eq('raw')
    end
  end
end
