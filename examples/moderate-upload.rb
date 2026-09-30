# Upload an image flagged for manual moderation, then record the verdict.
#
# Note: a "pending" asset is still deliverable — moderation status is metadata your
# application gates on, not an access control. See the docs page.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby moderate-upload.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/moderate-upload.md

require "cloudinary"

SOURCE = "https://res.cloudinary.com/demo/image/upload/sample.jpg".freeze
PUBLIC_ID = "examples/moderated-sample".freeze

# The upload response has no "moderation_status" key — only a "moderation" array.
# Reading it from the array works for every response shape.
def moderation_status(response)
  response["moderation"]&.first&.fetch("status", nil)
end

def main
  result = Cloudinary::Uploader.upload(
    SOURCE, public_id: PUBLIC_ID, moderation: "manual", overwrite: true
  )
  puts "Uploaded #{result['public_id']} -> #{moderation_status(result)}"

  pending = Cloudinary::Api.resources_by_moderation("manual", "pending", max_results: 100)
  puts "Awaiting review: #{pending['resources'].size} asset(s)"

  # Record the verdict. This does not change what the delivery URL serves — your own
  # code decides whether to render the asset based on this status.
  updated = Cloudinary::Api.update(PUBLIC_ID, moderation_status: "approved")
  puts "Now: #{moderation_status(updated)}"

  deliverable = moderation_status(updated) == "approved"
  puts "Render it? #{deliverable} (the URL itself works either way)"
end

begin
  main
rescue Cloudinary::Api::RateLimited => e
  # An unsubscribed add-on moderation kind also surfaces as a rate-limit error.
  warn "Rate limited or add-on not enabled: #{e.message}"
  exit 1
rescue StandardError => e
  warn "Moderation flow failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
