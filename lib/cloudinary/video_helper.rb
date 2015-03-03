require 'active_support/core_ext/hash/keys'


module CloudinaryHelper
  include ActionView::Context
  def cl_video_tag(sources, options = {})
      options = Hash[options]
      mapping = {
        :html_width => :width,
        :html_height => :height,
        :html_size => :size,
        :html_border => :border
      }
      options.transform_keys! { |key| mapping[key] || key}
      sources = Array(sources).map! {|source| cloudinary_url_internal source, options.dup }


      video_tag_without_cloudinary sources, options

    end


end





