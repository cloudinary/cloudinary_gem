require 'spec_helper'
require 'cloudinary'

describe Cloudinary::SearchFolders do
  context 'unit' do
    it "should search folders" do
      expected = {
        :url => /.*\/folders\/search$/,
        :method => :post,
        :payload => {
          "expression" => "path:test*",
        }.to_json
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      Cloudinary::SearchFolders
        .expression("path:test*")
        .execute
    end
  end
end
