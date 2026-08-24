# Build Cloudinary image delivery URLs: optimized, chained, and cache-busted.
#
# URL generation is local — it needs only a cloud_name, makes no network call, and
# never uses your api_secret.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby transform-and-deliver-image.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/transform-and-deliver-image.md

require "cloudinary"

# 'sample' ships with every new Cloudinary account.
PUBLIC_ID = "sample".freeze

def main
  thumbnail = Cloudinary::Utils.cloudinary_url(
    PUBLIC_ID,
    width: 200, height: 200, crop: "thumb",
    gravity: "auto",       # focus the crop on the most interesting region
    fetch_format: "auto",  # best format for the requesting browser
    quality: "auto"        # perceptual quality tuning
  )
  puts "Thumbnail: #{thumbnail}"

  # Chained: each component runs on the output of the previous one. Order matters.
  banner = Cloudinary::Utils.cloudinary_url(
    PUBLIC_ID,
    transformation: [
      { width: 1280, height: 720, crop: "fill", gravity: "auto" },
      { overlay: { font_family: "Arial", font_size: 64, font_weight: "bold", text: "SALE" },
        color: "white", gravity: "south_east", x: 24, y: 24 },
      { fetch_format: "auto", quality: "auto" }
    ]
  )
  puts "Banner:    #{banner}"

  # Generative edits are serialized as plain transformation strings.
  puts "No bg:     #{Cloudinary::Utils.cloudinary_url(PUBLIC_ID, effect: 'background_removal')}"

  # Deliver a specific version to bust CDN caches after re-uploading the same public_id.
  puts "Versioned: #{Cloudinary::Utils.cloudinary_url(PUBLIC_ID, version: 1234567890)}"
end

begin
  main
rescue StandardError => e
  warn "URL generation failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
