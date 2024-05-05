require 'spec_helper'
require 'cloudinary'

describe Cloudinary::AccountApi do
  config = Cloudinary.account_config

  if [config.provisioning_api_key, config.provisioning_api_secret, config.account_id].any? { |c| c.nil? || c.empty? }
    break puts("Please setup environment for account api test to run")
  end

  describe "Account Provisioning API" do
    attr_accessor :cloud_id, :user_id_1, :user_id_2, :group_id



    before :all do
      @api = Cloudinary::AccountApi

      @sub_account_name = "ruby-jutaname#{SUFFIX}"
      @sub_account_cloud_name = "ruby-jutaname#{SUFFIX}"
      @user_name_1 = "SDK RUBY TEST #{SUFFIX}"
      @user_name_2 = "SDK RUBY TEST 2 #{SUFFIX}"
      @user_email_1 = "sdk-test+#{SUFFIX}@cloudinary.com"
      @user_email_2 = "sdk-test2+#{SUFFIX}@cloudinary.com"
      @user_role = 'billing'
      @user_group_name = "test-ruby-group#{SUFFIX}"

      # create a sub account(sub cloud)
      @sub_account = @api.create_sub_account(@sub_account_name, @sub_account_cloud_name, {}, true)
      self.cloud_id = @sub_account["id"]

      # create users
      @user_1 = @api.create_user(@user_name_1, @user_email_1, @user_role, [])
      self.user_id_1 = @user_1["id"]

      @user_2 = @api.create_user(@user_name_2, @user_email_2, @user_role, [])
      self.user_id_2 = @user_2["id"]

      # create a user group
      @user_group = @api.create_user_group(@user_group_name)
      self.group_id = @user_group["id"]
    end

    after :all do
      del_sub_account_res = @api.delete_sub_account(cloud_id)
      expect(del_sub_account_res["message"]).to eq("ok")

      del_user_1_res = @api.delete_user(user_id_1)
      expect(del_user_1_res["message"]).to eq("ok")

      del_user_2_res = @api.delete_user(user_id_2)
      expect(del_user_2_res["message"]).to eq("ok")

      del_group_res = @api.delete_user_group(group_id)
      expect(del_group_res["ok"]).to eq(true) # notice the different response structure
    end

    it "should accept credentials as an argument" do
      new_name = "This wont be created"
      options = {
        provisioning_api_key: "abc",
        provisioning_api_secret: "abc"
      }

      expect { @api.create_sub_account(cloud_id, new_name, {}, nil, nil, options) }
        .to raise_error(Cloudinary::AccountApi::AuthorizationRequired)
    end

    it "should update a sub account" do
      new_name = "new-test-name"
      @api.update_sub_account(cloud_id, new_name)

      sub_acc_res = @api.sub_account(cloud_id)
      expect(sub_acc_res["name"]).to eq(new_name)
    end

    it "should get all sub accounts" do
      item = @api.sub_accounts(true)["sub_accounts"].find { |acc| acc["id"] == cloud_id }

      expect(item).to_not be_nil
    end

    it "should get a specific subAccount" do
      expect(@api.sub_account(cloud_id)["id"]).to eq(cloud_id)
    end

    it "should update a user" do
      new_email_address = "updated+#{Time.now.to_i}@cloudinary.com"

      @api.update_user(user_id_1, "updated", new_email_address).tap do |res|
        expect(res["name"]).to eq("updated")
        expect(res["email"]).to eql(new_email_address)
      end

      @api.user(user_id_1).tap do |res|
        expect(res["id"]).to eq(user_id_1)
        expect(res["email"]).to eq(new_email_address)
      end

      user = @api.users["users"].find { |u| u["id"] == user_id_1 }

      expect(user["id"]).to eq(user_id_1)
      expect(user["email"]).to eq(new_email_address)
    end

    it "should get users in a list of userIDs" do
      expect(@api.users(nil, [user_id_1])["users"].count).to eq 1
    end

    it "should get pending users" do
      result = @api.users(true, [user_id_1])
      expect(result["users"].count).to eq(1)
    end

    it "should get non-pending users" do
      result = @api.users(false, [user_id_1])
      expect(result["users"].count).to eq(0)
    end

    it "should get pending and non-pending users" do
      result = @api.users(nil, [user_id_1])
      expect(result["users"].count).to eq(1)
    end

    it "should get users by prefix" do
      result_1 = @api.users(true, nil, @user_name_2.slice(0..-2))
      result_2 = @api.users(true, nil, "#{@user_name_2}zzz")

      expect(result_1["users"].count).to eq(1)
      expect(result_2["users"].count).to eq(0)
    end

    it "should get users by sub_account_id" do
      result = @api.users(true, nil, @user_name_2, cloud_id)
      expect(result["users"].count).to eq(1)
    end

    it "should throw an error when attempting to get users by a nonexistent sub_account_id" do
      expect { @api.users(true, nil, nil, UNIQUE_TEST_ID) }
        .to raise_error("Cannot find sub account with id #{UNIQUE_TEST_ID}")
    end

    it "should update the user group" do
      new_name = "new-test-name_#{Time.now.to_i}"
      res = @api.update_user_group(group_id, new_name)
      expect(res["id"]).to eq(group_id)
      group_data = @api.user_group(group_id)
      expect(group_data["name"]).to eq(new_name)
    end

    it "should add and remove a user from a group" do
      res = @api.add_user_to_group(group_id, user_id_1)
      expect(res["users"].count).to eq(1)

      group_user_data = @api.user_group_users(group_id)
      expect(group_user_data["users"].count).to eq(1)

      rem_user_from_group_resp = @api.remove_user_from_group(group_id, user_id_1)
      expect(rem_user_from_group_resp["users"].count).to eq(0)
    end

    it "should test userGroups in account" do
      matched_group = @api.user_groups["user_groups"].find { |g| g["id"] == group_id }

      # Ensure we can find our ID in the list(Which means we got a real list as a response)
      expect(matched_group["id"]).to eq(group_id)
    end

    it "should get user by last login true" do
      time_millis = (Time.now.to_f.round(3) * 1000).to_i
      user_name = "SDK TEST Get Users By Last Login True #{time_millis}"
      user_email = "sdk-test-get-users-by-llt+#{time_millis}@cloudinary.com"

      user = @api.create_user(user_name, user_email, @user_role, [])
      user_id = user["id"]

      user_by_last_login = @api.users(true, [], user_name, nil,
                                     :last_login => true, :from => Date.today, :to => Date.today)
      expect(user_by_last_login["users"].count).to eq(0)

      del_user_res = @api.delete_user(user_id)
      expect(del_user_res["message"]).to eq("ok")
    end

    it "should get user by last login false" do
      time_millis = (Time.now.to_f.round(3) * 1000).to_i
      user_name = "SDK TEST Get Users By Last Login False #{time_millis}"
      user_email = "sdk-test-get-users-by-llf+#{time_millis}@cloudinary.com"

      user = @api.create_user(user_name, user_email, @user_role, [])
      user_id = user["id"]

      user_by_last_login = @api.users(true, [], user_name, nil,
                                     :last_login => false, :from => Date.today, :to => Date.today)
      expect(user_by_last_login["users"].count).to eq(1)

      del_user_res = @api.delete_user(user_id)
      expect(del_user_res["message"]).to eq("ok")
    end

    it "should list access keys" do
      access_keys = @api.access_keys(cloud_id)

      expect(access_keys['total']).to eq 1
      expect(access_keys['access_keys'].count).to eq 1
    end

    it "should generate access key" do
      access_key = @api.generate_access_key(cloud_id, 'test_key', false)

      expect(access_key['name']).to eq 'test_key'
      expect(access_key['enabled']).to be_falsey
    end

    it "should update access key" do
      access_key = @api.generate_access_key(cloud_id, 'test_key_for_update', false)

      expect(access_key['name']).to eq 'test_key_for_update'
      expect(access_key['enabled']).to be_falsey

      updated_key = @api.update_access_key(cloud_id, access_key['api_key'], 'updated_key', true)

      expect(updated_key['name']).to eq 'updated_key'
      expect(updated_key['enabled']).to be_truthy
    end

    it "should delete access key" do
      key_name =  UNIQUE_TEST_ID + "_delete_key"
      named_key_name = UNIQUE_TEST_ID + "_delete_by_name_key"

      access_key = @api.generate_access_key(cloud_id, key_name)
      named_access_key = @api.generate_access_key(cloud_id, named_key_name)

      expect(access_key["name"]).to eq key_name
      expect(named_access_key["name"]).to eq named_key_name

      key_del_res = @api.delete_access_key(cloud_id, access_key["api_key"])
      expect(key_del_res["message"]).to eq "ok"

      named_key_del_res = @api.delete_access_key(cloud_id, nil, named_key_name)
      expect(named_key_del_res["message"]).to eq "sok"
    end
  end
end
