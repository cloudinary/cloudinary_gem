# Search Cloudinary assets and read details for one of them.
#
# Run examples/upload-image.rb first so there is something to find. The search index lags
# writes by a short interval, so a brand-new upload may not appear immediately.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby search-and-manage-assets.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/search-and-manage-assets.md

require "cloudinary"

# Match on the public_id prefix: `folder:examples` returns nothing in a dynamic-folder
# product environment, which is the default for new clouds.
EXPRESSION = "resource_type:image AND public_id:examples/*".freeze

def main
  result = Cloudinary::Search
           .expression(EXPRESSION)
           .sort_by("created_at", "desc")
           .max_results(30)
           .execute

  puts "Matched #{result['total_count']} asset(s)"
  result["resources"].each do |asset|
    puts "  #{asset['public_id']}  #{asset['bytes']} bytes  #{asset['created_at']}"
  end

  # Admin responses carry rate-limit headers; slow down before you are cut off.
  puts "Admin API calls remaining: #{result.rate_limit_remaining}" if result.rate_limit_remaining

  first = result["resources"].first
  return puts "Nothing to inspect yet — run upload-image.rb first." if first.nil?

  # asset_id is immutable; look up by it, then use public_id for calls that require it.
  details = Cloudinary::Api.resource_by_asset_id(first["asset_id"])
  puts "Details for #{details['public_id']}: #{details['format']} #{details['width']}x#{details['height']}"
rescue Cloudinary::Api::RateLimited => e
  warn "Rate limited: #{e.message}"
  exit 1
end

begin
  main
rescue StandardError => e
  warn "Search failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
