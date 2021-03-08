class Cloudinary::Api
  extend Cloudinary::BaseApi

  # Ping Cloudinary servers.
  #
  # @see https://cloudinary.com/documentation/admin_api#ping Ping Cloudinary servers
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] The current status of the Cloudinary servers
  # @raise [Cloudinary::Api::Error]
  def self.ping(options={})
    call_api(:get, "ping", {}, options)
  end

  # Gets account usage details.
  #
  # Get a report on the status of your Cloudinary account usage details, including
  # storage, bandwidth, requests, number of resources, and add-on usage.
  # Note that numbers are updated periodically.
  #
  # @see https://cloudinary.com/documentation/admin_api#get_account_usage_details Get account usage details
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] The usage of the report
  # @raise [Cloudinary::Api:Error]
  def self.usage(options={})
    uri = 'usage'
    date = options[:date]

    uri += "/#{Cloudinary::Utils.to_usage_api_date_format(date)}" unless date.nil?

    call_api(:get, uri, {}, options)
  end

  # Returns available resource types.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Available resource types
  # @raise [Cloudinary::Api::Error]
  def self.resource_types(options={})
    call_api(:get, "resources", {}, options)
  end

  # Lists resources (assets) uploaded to your account.
  #
  # see https://cloudinary.com/documentation/admin_api#get_resources Get all images
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of resources
  # @raise [Cloudinary::Api::Error]
  def self.resources(options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type]
    uri           = "resources/#{resource_type}"
    uri           += "/#{type}" unless type.blank?
    call_api(:get, uri, only(options, :next_cursor, :max_results, :prefix, :tags, :context, :moderations, :direction, :start_at, :metadata), options)
  end

  # Retrieve a list of resources with a specified tag. This method does not return deleted resources even if they have been backed up.
  #
  # see https://cloudinary.com/documentation/admin_api#get_resources_by_tag Get resources by tag
  #
  # @param [String] tag Delete all assets (and their derivatives) with the given tag name
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of resources with a specified tag
  # @raise [Cloudinary::Api::Error]
  def self.resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/tags/#{tag}"
    call_api(:get, uri, only(options, :next_cursor, :max_results, :tags, :context, :moderations, :direction, :metadata), options)
  end

  # Retrieves resources (assets) with a particular status from a specified moderation queue.
  #
  # see https://cloudinary.com/documentation/admin_api#get_resources_in_moderation_queues Get resources in moderation queues
  #
  # @param [String] kind The type of moderation queue to list. Possible values: manual, webpurify, aws_rek, metascan
  # @param [String] status The moderation status of assets to retrieve. Possible values: pending, approved, rejected
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of resources with a particular status from a specified moderation queue
  # @raise [Cloudinary::Api::Error]
  def self.resources_by_moderation(kind, status, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/moderations/#{kind}/#{status}"
    call_api(:get, uri, only(options, :next_cursor, :max_results, :tags, :context, :moderations, :direction, :metadata), options)
  end

  # Retrieve a list of resources with a specified context key. This method does not return deleted resources even if they have been backed up.
  #
  # see https://cloudinary.com/documentation/admin_api#get_resources_by_context Get resources by context
  #
  # @param [String] key Only assets with this contextual metadata key are returned
  # @param [String] value Only assets with this contextual metadata value are returned
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of resources with a specified contextual metadata key
  # @raise [Cloudinary::Api::Error]
  def self.resources_by_context(key, value=nil, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/context"
    params = only(options, :next_cursor, :max_results, :tags, :context, :moderations, :direction, :key, :value, :metadata)
    params[:key] = key
    params[:value] = value
    call_api(:get, uri, params, options)
  end

  # Get all uploaded images with the given IDs.
  # @param [Array] public_ids The public IDs of assets
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of resources with the given IDs
  # @raise [Cloudinary::Api::Error]
  def self.resources_by_ids(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:get, uri, only(options, :tags, :context, :moderations).merge(:public_ids => public_ids), options)
  end

  # Return details of the requested resource (asset) as well as all its derived assets.
  #
  # see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_resource Get the details of a single resource
  #
  # @param [String] public_id The public ID of the asset
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details of the requested resource
  # @raise [Cloudinary::Api::Error]
  def self.resource(public_id, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}/#{public_id}"
    call_api(:get, uri,
             only(options,
                  :cinemagraph_analysis,
                  :colors,
                  :coordinates,
                  :exif,
                  :faces,
                  :image_metadata,
                  :max_results,
                  :pages,
                  :phash,
                  :quality_analysis,
                  :derived_next_cursor,
                  :accessibility_analysis,
                  :versions
             ), options)
  end

  # Restores one or more resources (assets) from backup.
  #
  # @param [Array] public_ids The public IDs of (deleted or existing) backed up assets to restore
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info for restored files
  # @raise [Cloudinary::Api::Error]
  def self.restore(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}/restore"
    call_api(:post, uri, { :public_ids => public_ids, :versions => options[:versions] }, options)
  end

  # Update one or more of the attributes associated with a specified resource (asset).
  #
  # see https://cloudinary.com/documentation/admin_api#update_details_of_an_existing_resource Update details of an existing resource
  #
  # @param [Object] public_id The public ID of the asset to update
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info for updated resource
  # @raise [Cloudinary::Api::Error]
  def self.update(public_id, options={})
    resource_type  = options[:resource_type] || "image"
    type           = options[:type] || "upload"
    uri            = "resources/#{resource_type}/#{type}/#{public_id}"
    update_options = {
      :access_control     => Cloudinary::Utils.json_array_param(options[:access_control]),
      :auto_tagging       => options[:auto_tagging] && options[:auto_tagging].to_f,
      :background_removal => options[:background_removal],
      :categorization     => options[:categorization],
      :context            => Cloudinary::Utils.encode_context(options[:context]),
      :custom_coordinates => Cloudinary::Utils.encode_double_array(options[:custom_coordinates]),
      :detection          => options[:detection],
      :face_coordinates   => Cloudinary::Utils.encode_double_array(options[:face_coordinates]),
      :moderation_status  => options[:moderation_status],
      :notification_url   => options[:notification_url],
      :quality_override   => options[:quality_override],
      :ocr                => options[:ocr],
      :raw_convert        => options[:raw_convert],
      :similarity_search  => options[:similarity_search],
      :tags               => options[:tags] && Cloudinary::Utils.build_array(options[:tags]).join(",")
    }
    call_api(:post, uri, update_options, options)
  end

  # Deletes resources (assets) uploaded to your account.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_resources Delete resources
  #
  # @param [Object] public_ids The list of public ids
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about deleted resources
  # @raise [Cloudinary::Api::Error]
  def self.delete_resources(public_ids, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :public_ids => public_ids ), options)
  end

  # Delete uploaded images by a prefix.
  # @param [Object] prefix The name of a prefix
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about deleted resources with a prefix
  # @raise [Cloudinary::Api::Error]
  def self.delete_resources_by_prefix(prefix, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :prefix => prefix), options)
  end

  # Delete all resources.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about all deleted resources
  # @raise [Cloudinary::Api::Error]
  def self.delete_all_resources(options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    call_api(:delete, uri, delete_resource_params(options, :all => true ), options)
  end

  # Deletes resources (assets) with a specified tag.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_resources_by_tags Delete resources by tags
  #
  # @param [String] tag The tag name
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about deleted resources with a tag
  # @raise [Cloudinary::Api::Error]
  def self.delete_resources_by_tag(tag, options={})
    resource_type = options[:resource_type] || "image"
    uri           = "resources/#{resource_type}/tags/#{tag}"
    call_api(:delete, uri, delete_resource_params(options), options)
  end

  # Deletes derived resources (assets) from your account.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_derived_resources Delete derived resources
  #
  # @param [Array] derived_resource_ids The list of ids
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about deleted derived resources from your account
  # @raise [Cloudinary::Api::Error]
  def self.delete_derived_resources(derived_resource_ids, options={})
    uri = "derived_resources"
    call_api(:delete, uri, { :derived_resource_ids => derived_resource_ids }, options)
  end

  # Delete derived resources identified by transformation for the provided public_ids.
  # @param [String|Array] public_ids The resources the derived resources belong to
  # @param [String|Hash|Array] transformations the transformation(s) associated with the derived resources
  # @param [Hash] options
  # @option options [String] :resource_type ("image")
  # @option options [String] :type ("upload")
  # @return [Cloudinary::Api::Response] Info about deleted derived resources for public_ids
  # @raise [Cloudinary::Api::Error]
  def self.delete_derived_by_transformation(public_ids, transformations, options={})
    resource_type = options[:resource_type] || "image"
    type          = options[:type] || "upload"
    uri           = "resources/#{resource_type}/#{type}"
    params = {:public_ids => public_ids}.merge(only(options, :invalidate))
    params[:keep_original] = true
    params[:transformations] = Cloudinary::Utils.build_eager(transformations)
    call_api(:delete, uri, params, options)
  end

  # Retrieve a list of all the tags currently used for a specified resource_type.
  #
  # see https://cloudinary.com/documentation/admin_api#tags Get tags
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of tags for all images
  # @raise [Cloudinary::Api::Error]
  def self.tags(options={})
    resource_type = options[:resource_type] || "image"
    uri           = "tags/#{resource_type}"
    call_api(:get, uri, only(options, :next_cursor, :max_results, :prefix), options)
  end

  # List all transformations.
  #
  # see https://cloudinary.com/documentation/admin_api#transformations Get Transformations
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of all transformations
  # @raise [Cloudinary::Api::Error]
  def self.transformations(options={})
    call_api(:get, "transformations", only(options, :named, :next_cursor, :max_results), options)
  end

  # Get details of a single transformation. Supply either the name of the transformation or the transformation parameters.
  #
  # see https://cloudinary.com/documentation/admin_api#get_transformation_details Get Transformation details
  #
  # @param [String] transformation The name of the transformation or the transformation parameters
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details of a single transformation
  # @raise [Cloudinary::Api::Error]
  def self.transformation(transformation, options={})
    call_api(:get, "transformations/#{transformation_string(transformation)}", only(options, :next_cursor, :max_results), options)
  end

  # Delete a single transformation. Supply either the name of the transformation or the transformation parameters.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_transformation Delete transformation
  #
  # @param [String] transformation The name of the transformation or the transformation parameters.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details of a single transformation
  # @raise [Cloudinary::Api::Error]
  def self.delete_transformation(transformation, options={})
    call_api(:delete, "transformations/#{transformation_string(transformation)}", {}, options)
  end

  # Update a single transformation. Supply either the name of the transformation or the transformation parameters.
  #
  # see https://cloudinary.com/documentation/admin_api#update_transformation Update transformation
  #
  # @param [String] transformation The name of the transformation or the transformation parameters
  # @param [Hash] updates Possible values:
  #   "allowed_for_strict" boolean,
  #   "unsafe_update" transformation params - updates a named transformation parameters without regenerating existing images
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about updated transformation
  # @raise [Cloudinary::Api::Error]
  def self.update_transformation(transformation, updates, options={})
    params                 = only(updates, :allowed_for_strict)
    params[:unsafe_update] = transformation_string(updates[:unsafe_update]) if updates[:unsafe_update]
    call_api(:put, "transformations/#{transformation_string(transformation)}", params, options)
  end

  # Create a new named transformation.
  #
  # see https://cloudinary.com/documentation/admin_api#create_a_named_transformation Create a named transformation
  #
  # @param [String] name The name of the transformation
  # @param [String] definition The transformation parameters
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about created transformation
  # @raise [Cloudinary::Api::Error]
  def self.create_transformation(name, definition, options={})
    call_api(:post, "transformations/#{name}", { :transformation => transformation_string(definition) }, options)
  end

  # Lists the upload presets defined for your account.
  #
  # see https://cloudinary.com/documentation/admin_api#upload_presets Get upload presets
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of the upload presets
  # @raise [Cloudinary::Api::Error]
  def self.upload_presets(options={})
    call_api(:get, "upload_presets", only(options, :next_cursor, :max_results), options)
  end

  # Retrieves the details of an upload preset.
  #
  # see https://cloudinary.com/documentation/admin_api#upload_preset Get the details of a single upload preset
  #
  # @param [String] name The name of the upload preset
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details of an upload preset
  # @raise [Cloudinary::Api::Error]
  def self.upload_preset(name, options={})
    call_api(:get, "upload_presets/#{name}", only(options, :max_results), options)
  end

  # Delete an existing upload preset.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_an_upload_preset Delete an upload preset
  #
  # @param [String] name The name of the upload preset
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about a deleted uploaded preset
  # @raise [Cloudinary::Api::Error]
  def self.delete_upload_preset(name, options={})
    call_api(:delete, "upload_presets/#{name}", {}, options)
  end

  # Update an existing upload preset.
  #
  # see https://cloudinary.com/documentation/admin_api#update_an_upload_preset Update an upload preset
  #
  # @param [String] name The name of the upload preset
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about an updated preset
  # @raise [Cloudinary::Api::Error]
  def self.update_upload_preset(name, options={})
    params = Cloudinary::Uploader.build_upload_params(options)
    call_api(:put, "upload_presets/#{name}", params.merge(only(options, :unsigned, :disallow_public_id)), options)
  end

  # Create a new upload preset.
  #
  # see https://cloudinary.com/documentation/admin_api#create_an_upload_preset Create an upload preset
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Message that upload was created
  # @raise [Cloudinary::Api::Error]
  def self.create_upload_preset(options={})
    params = Cloudinary::Uploader.build_upload_params(options)
    call_api(:post, "upload_presets", params.merge(only(options, :name, :unsigned, :disallow_public_id)), options)
  end

  # Lists all the root folders.
  #
  # see https://cloudinary.com/documentation/admin_api#get_root_folders Get root folders
  #
  # @param [Hash] options
  # @return [Cloudinary::Api::Response] Array of all the root folders
  # @raise [Cloudinary::Api::Error]
  def self.root_folders(options={})
    params = only(options, :max_results, :next_cursor)
    call_api(:get, "folders", params, options)
  end

  # Lists the name and path of all the subfolders of a given folder.
  #
  # see https://cloudinary.com/documentation/admin_api#get_subfolders Get subfolders
  #
  # @param [String] of_folder_path The full path of the folder to return subfolders of.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Array of all the subfolders of the given folder
  # @raise [Cloudinary::Api::Error]
  def self.subfolders(of_folder_path, options={})
    params = only(options, :max_results, :next_cursor)
    call_api(:get, "folders/#{of_folder_path}", params, options)
  end

  # Deletes an empty folder.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_folder Delete folder
  #
  # @param [String] path The full path of the empty folder to delete.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] The message that folder was deleted
  # @raise [Cloudinary::Api::Error]
  def self.delete_folder(path, options={})
    call_api(:delete, "folders/#{path}", {}, options)
  end

  # Create a new empty folder.
  #
  # see https://cloudinary.com/documentation/admin_api#create_folder Create folder
  #
  # @param [String] folder_name The full path of the new folder to create.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Info about created folder
  # @raise [Cloudinary::Api::Error]
  def self.create_folder(folder_name, options={})
    call_api(:post, "folders/#{folder_name}", {}, options)
  end

  # List all upload mappings by folder and includes its mapped template (URL).
  #
  # see https://cloudinary.com/documentation/admin_api#get_upload_mappings Get upload mappings
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] List of all upload mappings
  # @raise [Cloudinary::Api::Error]
  def self.upload_mappings(options={})
    params = only(options, :next_cursor, :max_results)
    call_api(:get, :upload_mappings, params, options)
  end

  # Retrieve the mapped template (URL) of a given upload mapping folder.
  #
  # see https://cloudinary.com/documentation/admin_api#get_the_details_of_a_single_upload_mapping Get the details of a single upload mapping
  #
  # @param [String] name The name of the folder to map.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Upload mapping details by a folder
  # @raise [Cloudinary::Api::Error]
  def self.upload_mapping(name=nil, options={})
    call_api(:get, 'upload_mappings', { :folder => name }, options)
  end

  # Delete an upload mapping by folder name.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_an_upload_mapping Delete an upload mapping
  #
  # @param [String] name The name of the folder to map.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Message about deleted folder
  # @raise [Cloudinary::Api::Error]
  def self.delete_upload_mapping(name, options={})
    call_api(:delete, 'upload_mappings', { :folder => name }, options)
  end

  # Update an existing upload mapping folder with a new template (URL).
  #
  # see https://cloudinary.com/documentation/admin_api#update_an_upload_mapping Update an upload mapping
  #
  # @param [String] name The name of the folder to map
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Message about updated mapping
  # @raise [Cloudinary::Api::Error]
  def self.update_upload_mapping(name, options={})
    params          = only(options, :template)
    params[:folder] = name
    call_api(:put, 'upload_mappings', params, options)
  end

  # Create a new upload mapping folder and its template (URL).
  #
  # see https://cloudinary.com/documentation/admin_api#create_an_upload_mapping Create an upload mapping
  #
  # @param [String] name The name of the folder to map
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Message about a created upload mapping
  # @raise [Cloudinary::Api::Error]
  def self.create_upload_mapping(name, options={})
    params          = only(options, :template)
    params[:folder] = name
    call_api(:post, 'upload_mappings', params, options)
  end

  # Create a new, custom streaming profile.
  #
  # see https://cloudinary.com/documentation/admin_api#create_a_streaming_profile Create a streaming profile
  #
  # @param [String] name The identification name to assign to the new streaming profile
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details for the streaming profile
  # @raise [Cloudinary::Api::Error]
  def self.create_streaming_profile(name, options={})
    params = only(options, :display_name, :representations)
    params[:representations] = params[:representations].map do |r|
      {:transformation => Cloudinary::Utils.generate_transformation_string(r[:transformation])}
    end.to_json
    params[:name] = name
    call_api(:post, 'streaming_profiles', params, options)
  end

  # List streaming profiles, including built-in and custom profiles.
  #
  # see https://cloudinary.com/documentation/admin_api#get_adaptive_streaming_profiles Get adaptive streaming profiles
  # @return [Cloudinary::Api::Response] Array of all the defined streaming profiles
  # @raise [Cloudinary::Api::Error]
  def self.list_streaming_profiles
    call_api(:get, 'streaming_profiles', {}, {})
  end

  # For custom streaming profiles, delete the specified profile.
  #
  # see https://cloudinary.com/documentation/admin_api#delete_streaming_profile Delete or revert the specified streaming profile
  #
  # @param [String] name The name of the streaming profile to delete or revert
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Message about a deleted streaming profiles
  # @raise [Cloudinary::Api::Error]
  def self.delete_streaming_profile(name, options={})
    call_api(:delete, "streaming_profiles/#{name}", {}, options)
  end

  # Retrieve the details of a single streaming profile by name.
  #
  # see https://cloudinary.com/documentation/admin_api#get_details_of_a_single_streaming_profile Get details of a single streaming profile
  #
  # @param [String] name The name of the streaming profile to get the details of
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details of a specified streaming file
  # @raise [Cloudinary::Api::Error]
  def self.get_streaming_profile(name, options={})
    call_api(:get, "streaming_profiles/#{name}", {}, options)
  end

  # Update the specified existing streaming profile.
  #
  # see https://cloudinary.com/documentation/admin_api#update_streaming_profile Update an existing streaming profile
  #
  # @param [Object] name The identification name to assign to the new streaming profile
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details for the streaming profile that was updated
  # @raise [Cloudinary::Api::Error]
  def self.update_streaming_profile(name, options={})
    params = only(options, :display_name, :representations)
    params[:representations] = params[:representations].map do |r|
      {:transformation => Cloudinary::Utils.generate_transformation_string(r[:transformation])}
    end.to_json
    call_api(:put, "streaming_profiles/#{name}", params, options)
  end

  # Update resources access mode. Resources are selected by the prefix.
  #
  # see https://cloudinary.com/documentation/admin_api#examples-8 Update the access mode of uploaded videos by prefix
  #
  # @param [String] access_mode the access mode to set the resources to
  # @param [String] prefix The prefix by which to filter applicable resources
  # @param [Object] options    additional options
  # @option options [String] :resource_type ("image") the type of resources to modify
  # @option options [Fixnum] :max_results (nil) the maximum resources to process in a single invocation
  # @option options [String] :next_cursor (nil) provided by a previous call to the method
  # @return [Cloudinary::Api::Response] Details for the uploaded images that were updated with a prefix
  # @raise [Cloudinary::Api::Error]
  def self.update_resources_access_mode_by_prefix(access_mode, prefix, options = {})
    update_resources_access_mode(access_mode, :prefix, prefix, options)
  end

  # Update resources access mode. Resources are selected by the tag.
  #
  # see https://cloudinary.com/documentation/admin_api#examples-8 Update the access mode of uploaded images by tag
  #
  # @param [String] access_mode the access mode to set the resources to
  # @param [String] tag the tag by which to filter applicable resources
  # @param [Object] options    additional options
  # @option options [String] :resource_type ("image") the type of resources to modify
  # @option options [Fixnum] :max_results (nil) the maximum resources to process in a single invocation
  # @option options [String] :next_cursor (nil) provided by a previous call to the method
  # @return [Cloudinary::Api::Response] Details for the uploaded images that were updated with a tag
  # @raise [Cloudinary::Api::Error]
  def self.update_resources_access_mode_by_tag(access_mode, tag, options = {})
    update_resources_access_mode(access_mode, :tag, tag, options)
  end

  # Update resources access mode. Resources are selected by the provided public_ids.
  #
  # see https://cloudinary.com/documentation/admin_api#examples-8 Update the access mode of uploaded images by public IDs
  #
  # @param [String] access_mode the access mode to set the resources to
  # @param [Array<String>] public_ids The prefix by which to filter applicable resources
  # @param [Object] options    additional options
  # @option options [String] :resource_type ("image") the type of resources to modify
  # @option options [Fixnum] :max_results (nil) the maximum resources to process in a single invocation
  # @option options [String] :next_cursor (nil) provided by a previous call to the method
  # @return [Cloudinary::Api::Response] Details for the uploaded images that were updated with IDs
  # @raise [Cloudinary::Api::Error]
  def self.update_resources_access_mode_by_ids(access_mode, public_ids, options = {})
    update_resources_access_mode(access_mode, :public_ids, public_ids, options)
  end

  # Execute a json call api with transformation breakpoints.
  # @param [Object] public_id Resource source
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details for the breakpoints
  # @raise [Cloudinary::Api::Error]
  def self.get_breakpoints(public_id, options)
    local_options = options.clone
    base_transformation = Cloudinary::Utils.generate_transformation_string(local_options)
    srcset = local_options[:srcset]
    breakpoints = [:min_width, :max_width, :bytes_step, :max_images].map {|k| srcset[k]}.join('_')

    local_options[:transformation] = [base_transformation, width: "auto:breakpoints_#{breakpoints}:json"]
    json_url = Cloudinary::Utils.cloudinary_url public_id, local_options
    call_json_api('GET', json_url, {}, 60, {})
  end

  # Returns a list of all metadata field definitions.
  #
  # @see https://cloudinary.com/documentation/admin_api#get_metadata_fields Get metadata fields API reference
  #
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details for metadata fields
  # @raise [Cloudinary::Api::Error]
  def self.list_metadata_fields(options = {})
    call_metadata_api(:get, [], {}, options)
  end

  # Gets a metadata field by external id.
  #
  # @see https://cloudinary.com/documentation/admin_api#get_a_metadata_field_by_external_id Get metadata field by external ID API reference
  #
  # @param [String] field_external_id The ID of the metadata field to retrieve
  # @param [Hash]   options           Additional options
  # @return [Cloudinary::Api::Response] Information for the metadata field with the ID
  # @raise [Cloudinary::Api::Error]
  def self.metadata_field_by_field_id(field_external_id, options = {})
    uri = [field_external_id]

    call_metadata_api(:get, uri, {}, options)
  end

  # Creates a new metadata field definition.
  #
  # @see https://cloudinary.com/documentation/admin_api#create_a_metadata_field Create metadata field API reference
  #
  # @param [Hash] field   The field to add
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Details for a new metadata field
  # @raise [Cloudinary::Api::Error]
  def self.add_metadata_field(field, options = {})
    params = only(field, :type, :external_id, :label, :mandatory, :default_value, :validation, :datasource)

    call_metadata_api(:post, [], params, options)
  end

  # Updates a metadata field by external id.
  #
  # Updates a metadata field definition (partially, no need to pass the entire object) passed as JSON data.
  # See https://cloudinary.com/documentation/admin_api#generic_structure_of_a_metadata_field for the generic structure
  # of a metadata field.
  #
  # @see https://cloudinary.com/documentation/admin_api#update_a_metadata_field_by_external_id Update metadata field API reference
  #
  # @param [String] field_external_id The id of the metadata field to update
  # @param [Hash]   field             The field definition
  # @param [Hash]   options           Additional options
  # @return [Cloudinary::Api::Response] Details for updated metadata field
  # @raise [Cloudinary::Api::Error]
  def self.update_metadata_field(field_external_id, field, options = {})
    uri = [field_external_id]
    params = only(field, :label, :mandatory, :default_value, :validation)

    call_metadata_api(:put, uri, params, options)
  end

  # Deletes a metadata field definition.
  #
  # The field should no longer be considered a valid candidate for all other endpoints.
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_a_metadata_field_by_external_id Delete metadata field API reference
  #
  # @param [String] field_external_id The external id of the field to delete
  # @param [Hash]   options           Additional options
  # @return [Cloudinary::Api::Response] A hash with a "message" key. "ok" value indicates a successful deletion
  # @raise [Cloudinary::Api::Error]
  def self.delete_metadata_field(field_external_id, options = {})
    uri = [field_external_id]

    call_metadata_api(:delete, uri, {}, options)
  end

  # Deletes entries in a metadata field datasource.
  #
  # Deletes (blocks) the datasource entries for a specified metadata field definition. Sets the state of the
  # entries to inactive. This is a soft delete, the entries still exist under the hood and can be activated
  # again with the restore datasource entries method.
  #
  # @see https://cloudinary.com/documentation/admin_api#delete_entries_in_a_metadata_field_datasource Delete entries in a metadata field datasource API reference
  #
  # @param [String] field_external_id    The id of the field to update
  # @param [Array]  entries_external_id  The ids of all the entries to delete from the datasource
  # @param [Hash]   options              Additional options
  # @return [Cloudinary::Api::Response] The remaining datasource entries
  # @raise [Cloudinary::Api::Error]
  def self.delete_datasource_entries(field_external_id, entries_external_id, options = {})
    uri = [field_external_id, "datasource"]
    params = {:external_ids => entries_external_id }

    call_metadata_api(:delete, uri, params, options)
  end

  # Updates a metadata field datasource.
  #
  # Updates the datasource of a supported field type (currently only enum and set), passed as JSON data. The
  # update is partial: datasource entries with an existing external_id will be updated and entries with new
  # external_id’s (or without external_id’s) will be appended.
  #
  # @see https://cloudinary.com/documentation/admin_api#update_a_metadata_field_datasource Update a metadata field datasource API reference
  #
  # @param [String] field_external_id   The external id of the field to update
  # @param [Array]  entries_external_id
  # @param [Hash]   options             Additional options
  # @return [Cloudinary::Api::Response] Details for a updated metadata field datasource
  # @raise [Cloudinary::Api::Error]
  def self.update_metadata_field_datasource(field_external_id, entries_external_id, options = {})
    uri = [field_external_id, "datasource"]

    params = entries_external_id.each_with_object({:values => [] }) do |item, hash|
      item = only(item, :external_id, :value)
      hash[:values ] << item if item.present?
    end

    call_metadata_api(:put, uri, params, options)
  end

  # Restores entries in a metadata field datasource.
  #
  # Restores (unblocks) any previously deleted datasource entries for a specified metadata field definition.
  # Sets the state of the entries to active.
  #
  # @see https://cloudinary.com/documentation/admin_api#restore_entries_in_a_metadata_field_datasource Restore entries in a metadata field datasource API reference
  #
  # @param [String] field_external_id    The ID of the metadata field
  # @param [Array]  entries_external_ids An array of IDs of datasource entries to restore (unblock)
  # @param [Hash]   options              Additional options
  # @return [Cloudinary::Api::Response] Details for a restored entries in a metadata field datasource
  # @raise [Cloudinary::Api::Error]
  def self.restore_metadata_field_datasource(field_external_id, entries_external_ids, options = {})
    uri = [field_external_id, "datasource_restore"]
    params = {:external_ids => entries_external_ids }

    call_metadata_api(:post, uri, params, options)
  end

  protected

  # Execute a call api for input params.
  # @param [Object] method The method for a request
  # @param [Object] uri The uri for a request
  # @param [Object] params Additional params
  # @param [Object] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.call_api(method, uri, params, options)
    cloud_name = options[:cloud_name] || Cloudinary.config.cloud_name || raise('Must supply cloud_name')
    api_key    = options[:api_key] || Cloudinary.config.api_key || raise('Must supply api_key')
    api_secret = options[:api_secret] || Cloudinary.config.api_secret || raise('Must supply api_secret')

    call_cloudinary_api(method, uri, api_key, api_secret, params, options) do |cloudinary, inner_uri|
      [cloudinary, 'v1_1', cloud_name, inner_uri]
    end
  end

  # Parse a json response.
  # @param [Object] response Returned response from Cloudinary
  # @return [Hash] Decoded string
  # @raise [Cloudinary::Api::GeneralError]
  def self.parse_json_response(response)
    return Cloudinary::Utils.json_decode(response.body)
  rescue => e
    # Error is parsing json
    raise GeneralError.new("Error parsing server response (#{response.code}) - #{response.body}. Got - #{e}")
  end

  # Protected function that assists with performing an API call to the metadata_fields part of the Admin API.
  #
  # @protected
  # @param [Symbol] method  The HTTP method. Valid methods: get, post, put, delete
  # @param [Array]  uri     REST endpoint of the API (without 'metadata_fields')
  # @param [Hash]   params  Query/body parameters passed to the method
  # @param [Hash]   options Additional options. Can be an override of the configuration, headers, etc.
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.call_metadata_api(method, uri, params, options)
    options[:content_type] = :json
    uri = ["metadata_fields", uri].reject(&:empty?).join("/")

    call_api(method, uri, params, options)
  end

  # Filter hash with specific keys.
  # @param [Object] hash Input hash
  # @param [Array] keys Input keys
  # @return [Hash] Result of hash filtering
  def self.only(hash, *keys)
    result = {}
    keys.each do |key|
      result[key] = hash[key] if hash.include?(key)
      result[key] = hash[key.to_s] if hash.include?(key.to_s)
    end
    result
  end

  # Merge params with a certain set of options.
  # @param [Object] options Set of options
  # @param [Hash] params Additional params
  # @return [Hash] Result of hash merging
  def self.delete_resource_params(options, params ={})
    params.merge(only(options, :keep_original, :next_cursor, :invalidate, :transformations))
  end

  # Generate a transformation string if an input a param is not a string.
  # @param [String|Hash] transformation Input transformation param
  # @return [String] Result of transformation
  def self.transformation_string(transformation)
    transformation.is_a?(String) ? transformation : Cloudinary::Utils.generate_transformation_string(transformation.clone)
  end

  # Publish resources.
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_resources(options = {})
    resource_type = options[:resource_type] || "image"
    params = only(options, :public_ids, :prefix, :tag, :type, :overwrite, :invalidate)
    call_api("post", "resources/#{resource_type}/publish_resources", params, options)
  end

  # Publish resources by a prefix.
  # @param [String] prefix The name of a prefix
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_prefix(prefix, options = {})
    return self.publish_resources(options.merge(:prefix => prefix))
  end

  # Publish resources by a tag.
  # @param [String] tag The name of a tag
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_tag(tag, options = {})
    return self.publish_resources(options.merge(:tag => tag))
  end

  # Publish resources by ids.
  # @param [Array] publicIds List of public ids
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.publish_by_ids(publicIds, options = {})
    return self.publish_resources(options.merge(:public_ids => publicIds))
  end

  # Build a link and prepare data for a call.
  # @param [String] access_mode The access_mode of resources
  # @param [Symbol] by_key The new access mode to be set. Possible values: public, authenticated.
  # @param [String|Array<String>] value The value to assign
  # @param [Hash] options Additional options
  # @return [Cloudinary::Api::Response] Returned response from Cloudinary
  # @raise [Cloudinary::Api::Error]
  def self.update_resources_access_mode(access_mode, by_key, value, options = {})
    resource_type = options[:resource_type] || "image"
    type = options[:type] || "upload"
    params = only(options, :next_cursor)
    params[:access_mode] = access_mode
    params[by_key] = value
    call_api("post", "resources/#{resource_type}/#{type}/update_access_mode", params, options)
  end
end
