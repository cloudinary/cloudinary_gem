require 'spec_helper'
require 'cloudinary'

module CarrierWave
  module Storage
    class Abstract
      def initialize(uploader)
        @uploader = uploader
      end

      attr_accessor :uploader
    end
  end
  class SanitizedFile; end
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
