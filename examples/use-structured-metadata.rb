# Define a structured metadata field, set it on an upload, and update it.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby use-structured-metadata.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/use-structured-metadata.md

require "cloudinary"

SOURCE = "https://res.cloudinary.com/demo/image/upload/sample.jpg".freeze
PUBLIC_ID = "examples/metadata-sample".freeze
FIELD_ID = "alt_text".freeze

# Fields are environment-level configuration: create once, not per upload.
def ensure_field_exists
  Cloudinary::Api.add_metadata_field(
    external_id: FIELD_ID, label: "Alt text", type: "string"
  )
  puts "Created metadata field '#{FIELD_ID}'"
rescue Cloudinary::Api::BadRequest => e
  raise unless e.message.include?("already exists")

  puts "Metadata field '#{FIELD_ID}' already exists"
end

def main
  ensure_field_exists

  # An undefined key rejects the whole upload — nothing is silently dropped.
  result = Cloudinary::Uploader.upload(
    SOURCE,
    public_id: PUBLIC_ID,
    overwrite: true,
    metadata: { FIELD_ID => "A close-up of a coastline" }
  )
  puts "Uploaded with metadata: #{result['metadata']}"

  updated = Cloudinary::Uploader.update_metadata({ FIELD_ID => "Updated caption" }, [PUBLIC_ID])
  puts "Updated: #{updated['public_ids']}"
end

begin
  main
rescue StandardError => e
  warn "Metadata flow failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
