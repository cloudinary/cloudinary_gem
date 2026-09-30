# Upload a video to Cloudinary in chunks with upload_large.
#
# Downloads a sample video from the Cloudinary demo account if it is not already present,
# so the script works with no arguments.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby upload-large-video.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/upload-large-video.md

require "cloudinary"
require "open-uri"

SAMPLE_VIDEO_URL = "https://res.cloudinary.com/demo/video/upload/dog.mp4".freeze
LOCAL_PATH = "dog.mp4".freeze
PUBLIC_ID = "examples/uploaded-large-video".freeze

# Use the local video if present; otherwise download the demo sample to that path.
def ensure_video_exists
  return LOCAL_PATH if File.exist?(LOCAL_PATH)

  puts "Downloading sample video..."
  URI.parse(SAMPLE_VIDEO_URL).open { |remote| File.binwrite(LOCAL_PATH, remote.read) }
  LOCAL_PATH
end

def main
  path = ensure_video_exists
  puts "Uploading #{path} (#{File.size(path)} bytes)"

  result = Cloudinary::Uploader.upload_large(
    path,
    resource_type: :video, # REQUIRED: upload_large defaults to :raw and would store an
                           # opaque blob that no video transformation can ever use
    chunk_size: 5_500_000, # 5 MB is the minimum Cloudinary accepts
    public_id: PUBLIC_ID,
    overwrite: true
  )

  puts "Uploaded: #{result['public_id']}"
  puts "Type:     #{result['resource_type']} (#{result['format']})"
  puts "Duration: #{result['duration']}s, #{result['bytes']} bytes"
  puts "URL:      #{result['secure_url']}"
end

begin
  main
rescue StandardError => e
  warn "Video upload failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
