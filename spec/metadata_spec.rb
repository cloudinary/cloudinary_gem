require 'spec_helper'
require 'cloudinary'

describe 'Metadata' do
  before(:all) do
    @id = UNIQUE_TEST_ID
    @api = Cloudinary::Api

    # External IDs for metadata fields that should be created and later deleted
    @metadata_fields = []
    @metadata_fields << @external_id_general = "metadata_external_id_general_#{@id}"
    @metadata_fields << @external_id_date = "metadata_external_id_date_#{@id}"
    @metadata_fields << @external_id_enum_2 = "metadata_external_id_enum_2_#{@id}"
    @metadata_fields << @external_id_set = "metadata_external_id_set_#{@id}"
    @metadata_fields << @external_id_set_2 = "metadata_external_id_set_2_#{@id}"
    @metadata_fields << @external_id_set_3 = "metadata_external_id_set_3_#{@id}"
    @metadata_fields << @external_id_delete_2 = "metadata_deletion_2_#{@id}"
    @metadata_fields << @external_id_date_validation = "metadata_date_validation_#{@id}"
    @metadata_fields << @external_id_date_validation_2 = "metadata_date_validation_2_#{@id}"
    @metadata_fields << @external_id_int_validation = "metadata_int_validation_#{@id}"
    @metadata_fields << @external_id_int_validation_2 = "metadata_int_validation_2_#{@id}"

     # External IDs for metadata fields that will be accessed through a mock (and should not be deleted or created)
    @external_id_string = "metadata_external_id_string_#{@id}"
    @external_id_int = "metadata_external_id_int_#{@id}"
    @external_id_enum = "metadata_external_id_enum_#{@id}"
    @external_id_delete = "metadata_deletion_#{@id}"

     # Sample datasource data
    @datasource_entry_external_id = "metadata_datasource_entry_external_id#{@id}"
    @datasource_single = [
      {
        'value' => 'v1',
        'external_id' => @datasource_entry_external_id
      }
    ]

    @datasource_multiple = [
      {
        'value' => 'v2',
        'external_id' => @datasource_entry_external_id,
      },
      {
        'value' => 'v3'
      },
      {
        'value' => 'v4'
      },
    ]

    @metadata_fields_to_create = [
      {
        'external_id' => @external_id_general,
        'type' => 'string'
      },
      {
        'external_id' => @external_id_enum_2,
        'type' => 'enum',
        'datasource' => {
          'values' => @datasource_multiple
        }
      },
      {
        'external_id' => @external_id_set_2,
        'type' => 'set',
        'datasource' => {
          'values' => @datasource_multiple
        }
      },
      {
        'external_id' => @external_id_set_3,
        'type' => 'set',
        'datasource' => {
          'values' => @datasource_multiple
        }
      },
      {
        'external_id' => @external_id_delete_2,
        'type' => 'integer'
      }
    ]

    begin
      @metadata_fields_to_create.each do |metadata_field_to_create|
        create_metadata_field_for_test(metadata_field_to_create)
      end
    rescue => e
      raise CloudinaryException, "Exception thrown while adding metadata field in metadata_spec::before(:all) - #{e}"
    end
  end

  after(:all) do
    begin
      @metadata_fields.each do |metadata_field|
        @api.delete_metadata_field(metadata_field)
      end
    rescue => e
      # Do nothing. Some exceptions while deleting are expected as we attempt to delete resources that are deleted in
      # deletion tests (just in case the test fail and they aren't deleted)
    end
  end

  # Private helper method to create a metadata field used during testing
  #
  # @param [Hash] field The field to add
  #
  # @return [Cloudinary::Api::Response]
  #
  # @raise [Error]
  def create_metadata_field_for_test(field)
    if field['label'].nil?
      field['label'] = field['external_id']
    end

    @api.add_metadata_field(field)
  end

  describe 'list_metadata_fields' do
    it 'should get a list of all metadata fields' do
      expected = {
        :url => /.*\/metadata_fields$/,
        :method => :get
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.list_metadata_fields
    end
  end

  describe 'metadata_field_by_field_id' do
    it 'should get a metadata field by external id' do
      result = @api.metadata_field_by_field_id(@external_id_general)

      expect(result).to be_a_metadata_field('string', 'label' => @external_id_general)
    end
  end

  describe 'add_metadata_field' do
    it 'should create a string metadata field' do
      field = { 'type' => 'string', 'external_id' => @external_id_string, 'label' => @external_id_string }

      expected = {
        :url => /.*\/metadata_fields$/,
        :method => :post,
        :payload => field.to_json,
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.add_metadata_field(field)
    end

    it 'should create an integer metadata field' do
      field = { 'type' => 'integer', 'external_id' => @external_id_int, 'label' => @external_id_int }

      expected = {
        :url => /.*\/metadata_fields$/,
        :method => :post,
        :payload => field.to_json
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.add_metadata_field(field)
    end

    it 'should create a date metadata field' do
      result = @api.add_metadata_field(
        'external_id' => @external_id_date,
        'label' => @external_id_date,
        'type' => 'date'
      )

      expect(result).to be_a_metadata_field('date', 'label' => @external_id_date, 'external_id' => @external_id_date, 'mandatory' => false)
    end

    it 'should create an enum metadata field' do
      field = {
        'type' => 'enum',
        'external_id' => @external_id_enum,
        'label' => @external_id_enum,
        'datasource' => {
          'values' => @datasource_single
        }
      }
      expected = {
        :url => /.*\/metadata_fields$/,
        :method => :post,
        :payload => field.to_json,
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.add_metadata_field(field)
    end

    it 'should create a set metadata field' do
      result = @api.add_metadata_field(
        'datasource' => {
          'values' => @datasource_multiple
        },
        'external_id' => @external_id_set,
        'label' => @external_id_set,
        'type' => 'set'
      )

      expect(result).to be_a_metadata_field('set', 'label' => @external_id_set, 'external_id' => @external_id_set, 'mandatory' => false)
    end

    it 'should validate default value of a date field' do
      past_date = (Date.today - 3).to_s
      yesterday_date = (Date.today - 1).to_s
      today_date = (Date.today).to_s
      future_date = (Date.today + 3).to_s

      last_three_days_validation = {
        'rules' => [
          {
            'type' => 'greater_than',
            'equals' => false,
            'value' => past_date
          },
          {
            'type' => 'less_than',
            'equals' => false,
            'value' => today_date
          },
        ],
        'type' => 'and'
      }

      # Test entering a metadata field with date validation and a valid default value
      metadata_field = {
        'external_id' => @external_id_date_validation,
        'label' => @external_id_date_validation,
        'type' => 'date',
        'default_value' => yesterday_date,
        'validation' => last_three_days_validation
      }

      result = @api.add_metadata_field(metadata_field)

      expect(result).to be_a_metadata_field('date', 'validation' => last_three_days_validation, 'default_value' => metadata_field['default_value'])

      # Test entering a metadata field with date validation and an invalid default value
      metadata_field = {
        'external_id' => @external_id_date_validation_2,
        'label' => @external_id_date_validation_2,
        'type' => 'date',
        'default_value' => future_date,
        'validation' => last_three_days_validation
      }

      expect {
        @api.add_metadata_field(metadata_field)
      }.to raise_error(@api::BadRequest)
    end

    it 'should validate default value of an integer field' do
      validation = {
        'type' => 'less_than',
        'equals' => true,
        'value' => 5
      }

      # Test entering a metadata field with integer validation and a valid default value
      metadata_field = {
        'external_id' => @external_id_int_validation,
        'label' => @external_id_int_validation,
        'type' => 'integer',
        'default_value' => 5,
        'validation' => validation
      }

      result = @api.add_metadata_field(metadata_field)

      expect(result).to be_a_metadata_field('integer', 'validation' => validation, 'default_value' => metadata_field['default_value'])

      # Test entering a metadata field with integer validation and an invalid default value
      metadata_field = {
        'external_id' => @external_id_int_validation_2,
        'label' => @external_id_int_validation_2,
        'type' => 'integer',
        'default_value' => 6,
        'validation' => validation
      }

      expect {
        @api.add_metadata_field(metadata_field)
      }.to raise_error(@api::BadRequest)
    end
  end

  describe 'update_metadata_field' do
    it 'should update a metadata field by external id' do
      new_label = "update_metadata_test_new_label#{@external_id_general}"
      new_default_value = "update_metadata_test_new_default_value#{@external_id_general}"

      # Call the API to update the metadata field
      # Will also attempt to update some fields that cannot be updated (external_id and type) which will be ignored
      result = @api.update_metadata_field(
        @external_id_general,
        {
          'external_id' => @external_id_set,
          'label' => new_label,
          'type' => 'integer',
          'mandatory' => true,
          'default_value' => new_default_value
        }
      )

      expect(result).to be_a_metadata_field('string', 'external_id' => @external_id_general, 'label' => new_label, 'default_value' => new_default_value, 'mandatory' => true)
    end
  end

  describe 'update_metadata_field_datasource' do
    it 'should update a metadata field datasource' do
      result = @api.update_metadata_field_datasource(@external_id_enum_2, @datasource_single)

      expect(result).to be_a_metadata_field_datasource
      expect(result['values']).to include(@datasource_single[0])
      expect(@datasource_multiple.count).to eq(result['values'].count)
      expect(@datasource_single[0]['value']).to eq(result['values'][0]['value'])
    end
  end

  describe 'delete_metadata_field' do
    it 'should delete a metadata field definition by its external id' do
      expected = {
        :url => /.*\/metadata_fields\/#{@external_id_delete}$/,
        :method => :delete,
        :payload => '{}',
      }

      expect(RestClient::Request).to receive(:execute).with(deep_hash_value(expected))

      @api.delete_metadata_field(@external_id_delete)
    end

    it 'should cause subsequent attempts to create a new metadata field with the same external id to fail' do
      @api.delete_metadata_field(@external_id_delete_2)

      expect {
        @api.add_metadata_field(
          'external_id' => @external_id_delete_2,
          'label' => @external_id_delete_2,
          'type' => 'integer'
        )
      }.to raise_error(@api::BadRequest)
    end
  end

  describe 'delete_datasource_entries' do
    it 'should delete entries in a metadata field datasource' do
      result = @api.delete_datasource_entries(
        @external_id_set_2,
        [
          @datasource_entry_external_id
        ]
      )

      expect(result).to be_a_metadata_field_datasource
      expect(@datasource_multiple.count - 1).to eq(result['values'].count)

      values = result['values'].map { |datasource_entity| datasource_entity['value'] }

      expect(values).to include(@datasource_multiple[1]['value'])
      expect(values).to include(@datasource_multiple[2]['value'])
    end
  end

  describe 'reorder_metadata_field_datasource' do
    it 'should order by asc in a metadata field datasource' do
      # datasource is set with values in the order v2, v3, v4
      result = @api.reorder_metadata_field_datasource(@external_id_set_3, 'value', 'asc')

      expect(result).to be_a_metadata_field_datasource

      # ascending order means v2 is the first value
      expect(result['values'][0]['value']).to eq('v2')
    end

    it 'should order by desc in a metadata field datasource' do
      # datasource is set with values in the order v2, v3, v4
      result = @api.reorder_metadata_field_datasource(@external_id_set_3, 'value', 'desc')

      expect(result).to be_a_metadata_field_datasource

      # descending order means v4 is the first value
      expect(result['values'][0]['value']).to eq('v4')
    end
  end

  describe 'restore_metadata_field_datasource' do
    it 'should restore a deleted entry in a metadata field datasource' do
      # Begin by deleting a datasource entry
      result = @api.delete_datasource_entries(
        @external_id_set_3,
        [
          @datasource_entry_external_id
        ]
      )

      expect(result).to be_a_metadata_field_datasource
      expect(result['values'].count).to eq(2)

      # Restore datasource entry
      result = @api.restore_metadata_field_datasource(
        @external_id_set_3,
        [
          @datasource_entry_external_id
        ]
      )

      expect(result).to be_a_metadata_field_datasource
      expect(result['values'].count).to eq(3)
    end
  end
end
