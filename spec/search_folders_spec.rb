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
        }
      }

      res = MockedSearchFoldersApi
        .expression("path:test*")
        .execute

      expect(res).to have_deep_hash_values_of(expected)
    end
  end
end
