require 'spec_helper'
require 'cloudinary'

describe 'Metadata Rules' do
  before(:all) do
    @id = UNIQUE_TEST_ID
    @api = Cloudinary::Api

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

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.list_metadata_rules
    end
  end

  describe 'add_metadata_rule' do
    it 'should create a metadata rule' do
      expected = {
        :url => /.*\/metadata_rules$/,
        :method => :post,
        :payload => @metadata_rule.to_json,
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.add_metadata_rule(@metadata_rule)
    end

  end

  describe 'update_metadata_rule' do
    it 'should update a metadata rule by external id' do
      expected = {
        :url => /.*\/metadata_rules\/#{@external_id_rule}$/,
        :method => :put,
        :payload => @metadata_rule_update.to_json,
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.update_metadata_rule(@external_id_rule, @metadata_rule_update)
    end
  end

  describe 'delete_metadata_rule' do
    it 'should delete a metadata rule by its external id' do
      expected = {
        :url => /.*\/metadata_rules\/#{@external_id_rule_delete}$/,
        :method => :delete,
        :payload => '{}',
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.delete_metadata_rule(@external_id_rule_delete)
    end
  end
end
