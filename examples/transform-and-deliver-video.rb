# Build Cloudinary video delivery URLs: derived asset, poster frame, and HLS manifest.
#
# URL generation is local — it needs only a cloud_name and makes no network call.
# Video URLs require resource_type: "video"; without it you get an image URL that 404s.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby transform-and-deliver-video.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/transform-and-deliver-video.md

require "cloudinary"

# Uploaded by upload-large-video.rb; 'dog' also exists on the demo account.
PUBLIC_ID = "examples/uploaded-large-video".freeze

def main
  video_url = Cloudinary::Utils.cloudinary_url(
    PUBLIC_ID,
    resource_type: "video",
    width: 640, height: 360, crop: "fill",
    quality: "auto", format: "mp4"
  )
  puts "MP4 derived asset: #{video_url}"

  # A poster frame is the same asset delivered as an image format at a timestamp.
  poster = Cloudinary::Utils.cloudinary_url(
    PUBLIC_ID,
    resource_type: "video", format: "jpg", start_offset: "2"
  )
  puts "Poster frame:      #{poster}"

  # Adaptive bitrate streaming: deliver a manifest instead of a single file.
  hls = Cloudinary::Utils.cloudinary_url(
    PUBLIC_ID,
    resource_type: "video", format: "m3u8", streaming_profile: "full_hd"
  )
  puts "HLS manifest:      #{hls}"
end

begin
  main
rescue StandardError => e
  warn "URL generation failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
