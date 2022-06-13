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
