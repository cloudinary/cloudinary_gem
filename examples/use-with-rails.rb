# Render the Cloudinary Rails view helpers without a full Rails application.
#
# In a real Rails app these helpers are available in every template automatically — the
# gem's railtie includes them. This script wires up ActionView by hand so you can see the
# exact markup they produce.
#
# Prerequisites: CLOUDINARY_URL must be set, and the actionview gem available.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby use-with-rails.rb
# In your own project: nothing to require — use cl_image_tag directly in a template.
#
# Docs: ../docs/use-with-rails.md

require "cloudinary"
require "action_view"
require "cloudinary/helper"
require "cloudinary/video_helper"

def view_context
  ActionView::Base.include(CloudinaryHelper)
  ActionView::Base.empty
end

def main
  view = view_context

  puts "cl_image_tag:"
  puts view.cl_image_tag("sample", width: 200, height: 200, crop: "fill",
                                   gravity: "auto", fetch_format: "auto", quality: "auto")
  puts

  puts "cl_image_path:"
  puts view.cl_image_path("sample")
  puts

  puts "cl_video_tag:"
  puts view.cl_video_tag("dog", width: 640, crop: "scale")
end

begin
  main
rescue StandardError => e
  warn "Rendering failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
