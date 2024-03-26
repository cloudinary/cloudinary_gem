require 'spec_helper'
require 'cloudinary'

describe 'Metadata Rules' do
  before(:all) do
    @id = UNIQUE_TEST_ID
    @api = Cloudinary::Api
    @mock_api = MockedApi

    @external_id_rule = "metadata_rule_#{@id}"
    @external_id_rule_delete = "metadata_rule_deletion_#{@id}"

    @metadata_rule = {
      "metadata_field_id" => "team",
      "condition" => {"metadata_field_id" => "category", "equals" => "employee"},
      "result" => { "enable" => true, "activate_values" => "all" },
      "name" => "category-employee"
    }

    @metadata_rule_update = @metadata_rule.clone
    @metadata_rule_update["state"] = "inactive"
    @metadata_rule_update.delete("metadata_field_id")

  end

  describe 'list_metadata_rules' do
    it 'should get a list of all metadata rules' do
      expected = {
        :url => /.*\/metadata_rules$/,
        :method => :get
      }

      res = @mock_api.list_metadata_rules

      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  describe 'add_metadata_rule' do
    it 'should create a metadata rule' do
      expected = {
        :url => /.*\/metadata_rules$/,
        :method => :post,
        :payload => @metadata_rule,
      }

      res = @mock_api.add_metadata_rule(@metadata_rule)

      expect(res).to have_deep_hash_values_of(expected)
    end

  end

  describe 'update_metadata_rule' do
    it 'should update a metadata rule by external id' do
      expected = {
        :url => /.*\/metadata_rules\/#{@external_id_rule}$/,
        :method => :put,
        :payload => @metadata_rule_update,
      }

      res = @mock_api.update_metadata_rule(@external_id_rule, @metadata_rule_update)

      expect(res).to have_deep_hash_values_of(expected)
    end
  end

  describe 'delete_metadata_rule' do
    it 'should delete a metadata rule by its external id' do
      expected = {
        :url => /.*\/metadata_rules\/#{@external_id_rule_delete}$/,
        :method => :delete,
        :payload => {},
      }

      res = @mock_api.delete_metadata_rule(@external_id_rule_delete)

      expect(res).to have_deep_hash_values_of(expected)
    end
  end
end
