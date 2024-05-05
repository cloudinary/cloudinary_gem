class Cloudinary::AccountApi
  extend Cloudinary::BaseApi

  # Creates a new sub-account. Any users that have access to all sub-accounts will also automatically have access to the
  # new sub-account.
  # @param [String] name The display name as shown in the management console
  # @param [String] cloud_name A case-insensitive cloud name comprised of alphanumeric and underscore characters.
  #   Generates an error if the specified cloud name is not unique across all Cloudinary accounts.
  #   Note: Once created, the name can only be changed for accounts with fewer than 1000 assets.
  # @param [Object] custom_attributes Any custom attributes you want to associate with the sub-account
  # @param [Boolean] enabled Whether to create the account as enabled (default is enabled)
  # @param [String] base_account ID of sub-account from which to copy settings
  # @param [Object] options additional options
  def self.create_sub_account(name, cloud_name = nil, custom_attributes = {}, enabled = nil, base_account = nil, options = {})
    params = {
      name:                name,
      cloud_name:          cloud_name,
      custom_attributes:   custom_attributes,
      enabled:             enabled,
      base_sub_account_id: base_account
    }

    call_account_api(:post, 'sub_accounts', params, options.merge(content_type: :json))
  end

  # Updates the specified details of the sub-account.
  # @param [String] sub_account_id The ID of the sub-account.
  # @param [String] name The display name as shown in the management console
  # @param [String] cloud_name A case-insensitive cloud name comprised of alphanumeric and underscore characters.
  #   Generates an error if the specified cloud name is not unique across all Cloudinary accounts.
  #   Note: Once created, the name can only be changed for accounts with fewer than 1000 assets.
  # @param [Object] custom_attributes Any custom attributes you want to associate with the sub-account, as a map/hash
  #   of key/value pairs.
  # @param [Boolean] enabled Whether the sub-account is enabled.
  # @param [Object] options additional options
  def self.update_sub_account(sub_account_id, name = nil, cloud_name = nil, custom_attributes = nil, enabled = nil, options = {})
    params = {
      name:              name,
      cloud_name:        cloud_name,
      custom_attributes: custom_attributes,
      enabled:           enabled
    }

    call_account_api(:put, ['sub_accounts', sub_account_id], params, options.merge(content_type: :json))
  end

  # Lists sub-accounts.
  # @param [Boolean] enabled Whether to only return enabled sub-accounts (true) or disabled accounts (false).
  #  Default: all accounts are returned (both enabled and disabled).
  # @param [Array<String>] ids A list of up to 100 sub-account IDs. When provided, other parameters are ignored.
  # @param [String] prefix Returns accounts where the name begins with the specified case-insensitive string.
  # @param [Object] options additional options
  def self.sub_accounts(enabled = nil, ids = [], prefix = nil, options = {})
    params = {
      enabled: enabled,
      ids:     ids,
      prefix:  prefix
    }

    call_account_api(:get, 'sub_accounts', params, options.merge(content_type: :json))
  end

  # Retrieves the details of the specified sub-account.
  # @param [String] sub_account_id The ID of the sub-account.
  # @param [Object] options additional options
  def self.sub_account(sub_account_id, options = {})
    call_account_api(:get, ['sub_accounts', sub_account_id], {}, options.merge(content_type: :json))
  end

  # Deletes the specified sub-account. Supported only for accounts with fewer than 1000 assets.
  # @param [String] sub_account_id The ID of the sub-account.
  # @param [Object] options additional options
  def self.delete_sub_account(sub_account_id, options = {})
    call_account_api(:delete, ['sub_accounts', sub_account_id], {}, options)
  end

  # Creates a new user in the account.
  # @param [String] name The name of the user.
  # @param [String] email A unique email address, which serves as the login name and notification address.
  # @param [String] role The role to assign. Possible values: master_admin, admin, billing, technical_admin, reports,
  #   media_library_admin, media_library_user
  # @param [Array<String>] sub_account_ids The list of sub-account IDs that this user can access.
  #   Note: This parameter is ignored if the role is specified as master_admin.
  # @param [Object] options additional options
  def self.create_user(name, email, role, sub_account_ids = [], options = {})
    params = {
      name:            name,
      email:           email,
      role:            role,
      sub_account_ids: sub_account_ids
    }

    call_account_api(:post, 'users', params, options.merge(content_type: :json))
  end

  # Deletes an existing user.
  # @param [String] user_id The ID of the user to delete.
  # @param [Object] options additional options
  def self.delete_user(user_id, options = {})
    call_account_api(:delete, ['users', user_id], {}, options)
  end

  # Updates the details of the specified user.
  # @param [String] user_id The ID of the user to update.
  # @param [String] name The name of the user.
  # @param [String] email A unique email address, which serves as the login name and notification address.
  # @param [String] role The role to assign. Possible values: master_admin, admin, billing, technical_admin, reports,
  #   media_library_admin, media_library_user
  # @param [Array<String>] sub_account_ids The list of sub-account IDs that this user can access.
  #   Note: This parameter is ignored if the role is specified as master_admin.
  # @param [Object] options additional options
  def self.update_user(user_id, name = nil, email = nil, role = nil, sub_account_ids = nil, options = {})
    params = {
      name:            name,
      email:           email,
      role:            role,
      sub_account_ids: sub_account_ids
    }

    call_account_api(:put, ['users', user_id], params, options.merge(content_type: :json))
  end

  # Returns the user with the specified ID.
  # @param [String] user_id The ID of the user.
  # @param [Object] options additional options
  def self.user(user_id, options = {})
    call_account_api(:get, ['users', user_id], {}, options.merge(content_type: :json))
  end

  # Get a list of the users according to filters.
  #
  # @param [Boolean]        pending        Optional. Limit results to pending users (true), users that are not pending (false), or all users (null)
  # @param [Array<String>]  user_ids       Optional. List of user IDs. Up to 100
  # @param [String]         prefix         Optional. Search by prefix of the user's name or email. Case-insensitive
  # @param [String]         sub_account_id Optional. Return only users who have access to the given sub-account
  # @param [Object]         options        Generic advanced options map, see online documentation.
  # @option options [Boolean] :last_login  Optional. Return only users that last logged in in the specified range of dates (true),
  #                                                users that didn't last logged in in that range (false), or all users (null).
  # @option options [Date]    :from        Optional. Last login start date.
  # @option options [Date]    :to          Optional. Last login end date.
  #
  # @return [Cloudinary::Api::Response] the users' details.
  #
  # @raise [Cloudinary::Api::Error] If the request fails.
  def self.users(pending = nil, user_ids = [], prefix = nil, sub_account_id = nil, options = {})
    params = {
      ids:            user_ids,
      prefix:         prefix,
      sub_account_id: sub_account_id,
      pending:        pending,
      last_login:     options[:last_login].to_s,
      from:           Cloudinary::Utils.to_usage_api_date_format(options[:from]),
      to:             Cloudinary::Utils.to_usage_api_date_format(options[:to])
    }

    call_account_api(:get, 'users', params, options.merge(content_type: :json))
  end

  # Creates a new user group.
  # @param [String] name The name for the user group.
  # @param [Object] options additional options
  def self.create_user_group(name, options = {})
    params = {
      name: name
    }

    call_account_api(:post, 'user_groups', params, options.merge(content_type: :json))
  end

  # Updates the specified user group.
  # @param [String] group_id The ID of the user group to update.
  # @param [String] name The name for the user group.
  # @param [Object] options additional options
  def self.update_user_group(group_id, name, options = {})
    params = {
      name: name
    }

    call_account_api(:put, ['user_groups', group_id], params, options.merge(content_type: :json))
  end

  # Adds a user to a group with the specified ID.
  # @param [String] group_id The ID of the user group.
  # @param [String] user_id The ID of the user.
  # @param [Object] options additional options
  def self.add_user_to_group(group_id, user_id, options = {})
    call_account_api(:post, ['user_groups', group_id, 'users', user_id], {}, options.merge(content_type: :json))
  end

  # Removes a user from a group with the specified ID.
  # @param [String] group_id The ID of the user group.
  # @param [String] user_id The ID of the user.
  # @param [Object] options additional options
  def self.remove_user_from_group(group_id, user_id, options = {})
    call_account_api(:delete, ['user_groups', group_id, 'users', user_id], {}, options.merge(content_type: :json))
  end

  # Deletes the user group with the specified ID.
  # @param [String] group_id The ID of the user group to delete.
  # @param [Object] options additional options
  def self.delete_user_group(group_id, options = {})
    call_account_api(:delete, ['user_groups', group_id], {}, options)
  end

  # Lists user groups in the account.
  # @param [Object] options additional options
  def self.user_groups(options = {})
    call_account_api(:get, 'user_groups', {}, options.merge(content_type: :json))
  end

  # Retrieves the details of the specified user group.
  # @param [String] group_id The ID of the user group to retrieve.
  # @param [Object] options additional options
  def self.user_group(group_id, options = {})
    call_account_api(:get, ['user_groups', group_id], {}, options.merge(content_type: :json))
  end

  # Lists users in the specified user group.
  # @param [String] group_id The ID of the user group.
  # @param [Object] options additional options
  def self.user_group_users(group_id, options = {})
    call_account_api(:get, ['user_groups', group_id, 'users'], {}, options.merge(content_type: :json))
  end

  # Lists access keys.
  #
  # @param [String] sub_account_id  The ID of the sub-account.
  # @param [Object] options         Additional options.
  def self.access_keys(sub_account_id, options = {})
    params = Cloudinary::Api.only(options, :page_size, :page, :sort_by, :sort_order)
    call_account_api(:get, ['sub_accounts', sub_account_id, 'access_keys'], params, options)
  end

  # Generates access key.
  #
  # @param [String]   sub_account_id  The ID of the sub-account.
  # @param [String]   name            The display name as shown in the management console.
  # @param [Boolean]  enabled         Whether to create the access key as enabled (default is enabled).
  # @param [Object]   options         Additional options.
  def self.generate_access_key(sub_account_id, name = nil, enabled = nil, options = {})
    params = {
      name:    name,
      enabled: enabled,
    }
    call_account_api(:post, ['sub_accounts', sub_account_id, 'access_keys'], params, options.merge(content_type: :json))
  end

  # Updates access key.
  #
  # @param [String]   sub_account_id  The ID of the sub-account.
  # @param [String]   api_key         The API key.
  # @param [String]   name            The display name as shown in the management console.
  # @param [Boolean]  enabled         Enable or disable the access key.
  # @param [Object]   options         Additional options.
  def self.update_access_key(sub_account_id, api_key, name = nil, enabled = nil, options = {})
    params = {
      name:    name,
      enabled: enabled,
    }
    call_account_api(:put, ['sub_accounts', sub_account_id, 'access_keys', api_key], params, options.merge(content_type: :json))
  end

  # Deletes access key.
  #
  # @param [String]        sub_account_id  The ID of the sub-account.
  # @param [String, nil]   api_key         The API key.
  # @param [String, nil]   name            The display name as shown in the management console.
  # @param [Object]        options         Additional options.
  def self.delete_access_key(sub_account_id, api_key = nil, name = nil, options = {})
    uri = ['sub_accounts', sub_account_id, 'access_keys']
    unless api_key.blank?
      uri.append(api_key)
    end

    params = {
      name: name,
    }
    call_account_api(:delete, uri, params, options.merge(content_type: :json))
  end

  def self.call_account_api(method, uri, params, options)
    account_id = options[:account_id] || Cloudinary.account_config.account_id || raise('Must supply account_id')
    api_key    = options[:provisioning_api_key] || Cloudinary.account_config.provisioning_api_key || raise('Must supply provisioning api_key')
    api_secret = options[:provisioning_api_secret] || Cloudinary.account_config.provisioning_api_secret || raise('Must supply provisioning api_secret')
    api_version = options[:api_version] || Cloudinary.config.api_version || 'v1_1'

    params.reject! { |_, v| v.nil? }
    auth = { :key => api_key, :secret => api_secret }

    call_cloudinary_api(method, uri, auth, params, options) do |cloudinary, inner_uri|
      [cloudinary, api_version, 'provisioning', 'accounts', account_id, inner_uri]
    end
  end

  private_class_method :call_account_api
end
