require 'active_support/core_ext/hash/keys'
# DONE add timeout option

module CloudinaryHelper
  include ActionView::Context
  include ActionView::Helpers::TagHelper
  DEFAULT_POSTER_OPTIONS = { :format => 'jpg', :resource_type => 'video' }
  DEFAULT_SOURCE_TYPES   = %w(webm mp4 ogv)
  DEFAULT_VIDEO_OPTIONS  = { :resource_type => 'video' }

  # Creates an HTML video tag for the provided +source+
  #
  # ==== Options
  # * <tt>:source_types</tt> - Specify which source type the tag should include. defaults to webm, mp4 and ogv.
  # * <tt>:source_transformation</tt> - specific transformations to use for a specific source type.
  # * <tt>:poster</tt> - override default thumbnail:
  #   * url: provide an ad hoc url
  #   * options: with specific poster transformations and/or Cloudinary +:public_id+
  #
  # ==== Examples
  #   cl_video_tag("mymovie.mp4")
  #   cl_video_tag("mymovie.mp4", :source_types => :webm)
  #   cl_video_tag("mymovie.ogv", :poster => "myspecialplaceholder.jpg")
  #   cl_video_tag("mymovie.webm", :source_types => [:webm, :mp4], :poster => {:effect => 'sepia'}) do
  #     content_tag( :span, "Cannot present video!")
  #   end
  def cl_video_tag(source, options = {}, &block) # DONE revise signature and don't use rails
    # DONE is type legit in video tag?
    video_attributes = [:autoplay,:controls,:loop,:muted,:poster, :preload]
    options = Hash[options].deep_symbolize_keys

    options[:source_types] ||= DEFAULT_SOURCE_TYPES

    video_options = options.extract!(*video_attributes)
    if video_options.has_key? :poster
      poster = video_options.delete(:poster)
      case poster
      when String
        video_options[:poster] = poster
      when Hash
        if poster.has_key? :public_id
          poster[:resource_type] = "image"
          poster_name            = poster[:public_id]
          video_options[:poster] = cl_image_path(poster_name, poster)
        else
          video_options[:poster] = cl_video_thumbnail_path(source, poster)
        end
      else
        # no poster
      end
    else
      video_options[:poster] = cl_video_thumbnail_path(source, options)
    end

    source_transformation = options.delete(:source_transformation) || {}
    source_types = Array(options.delete(:source_types))
    fallback     = (capture(&block) if block_given?) || options.delete(:fallback_content)

    if source_types.size > 1
      cloudinary_tag(source, options) do |_, tag_options|
        content_tag('video', tag_options.merge(video_options)) do
          source_tags = source_types.map do |type|
            transformation = (source_transformation[type.to_sym] || {}).symbolize_keys
            logger.debug tag_options.merge(transformation)
            cloudinary_tag("#{source}.#{type}", tag_options.merge(transformation)) do |url, _|
              tag("source", :src => url, :type => "video/#{type}")
              # tag("source", :src => cl_video_path("#{source}.#{type}", options.merge(transformation)), :type => "video/#{type}")
            end
          end
          source_tags.push(fallback.html_safe) unless fallback.blank?
          safe_join(source_tags)
        end
      end
    else
      transformation      = source_transformation[source_types.first.to_sym] || {}
      video_options[:src] = cl_video_path("#{source}.#{source_types.first.to_sym}", transformation.merge(options))
      cloudinary_tag(source, options) do |url, tag_options|
        content_tag('video', fallback, tag_options.merge(video_options))
      end
    end
  end

  # Returns a url for the given source with +options+
  def cl_video_path(source, options={})
    cl_image_path(source, DEFAULT_VIDEO_OPTIONS.merge(options))
  end

  # Returns an HTML <tt>img</tt> tag with the thumbnail for the given video +source+ and +options+
  def cl_video_thumbnail_tag(source, options={})
    cl_image_tag(source, DEFAULT_POSTER_OPTIONS.merge(options))
  end

  # Returns a url for the thumbnail for the given video +source+ and +options+
  def cl_video_thumbnail_path(source, options={})
    cl_image_path(source, DEFAULT_POSTER_OPTIONS.merge(options))
  end

  protected

  def strip_known_ext(name)
    has_known_ext?(name) ? name.split('.')[0..-2].join('.') : name
  end

  def has_known_ext?(name)
    (/\.(#{DEFAULT_SOURCE_TYPES.join("|")})$/ =~ name).nil?
  end
end





