# Upload an image to Cloudinary and print the delivery URL.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby upload-image.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/upload-image.md

require "cloudinary"

SOURCE = "https://res.cloudinary.com/demo/image/upload/sample.jpg".freeze
PUBLIC_ID = "examples/uploaded-sample".freeze

def main
  result = Cloudinary::Uploader.upload(SOURCE, public_id: PUBLIC_ID, overwrite: true)

  puts "Uploaded: #{result['public_id']}"
  puts "Asset ID: #{result['asset_id']}" # immutable; survives renames
  puts "Format:   #{result['format']} #{result['width']}x#{result['height']} #{result['bytes']} bytes"
  puts "URL:      #{result['secure_url']}"
end

begin
  main
rescue StandardError => e
  # Configuration errors raise CloudinaryException from Uploader but RuntimeError from
  # Api/Search, so rescue StandardError to cover both. See ../docs/troubleshoot-errors.md
  warn "Upload failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
