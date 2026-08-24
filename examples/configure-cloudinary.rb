# Show which Cloudinary configuration the SDK actually resolved, and validate it.
#
# Useful as a first diagnostic when calls fail with "Must supply cloud_name".
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby configure-cloudinary.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/configure-cloudinary.md

require "cloudinary"

REQUIRED_KEYS = %w[cloud_name api_key api_secret].freeze

def main
  puts "SDK version: #{Cloudinary::VERSION}"
  puts "cloud_name:  #{Cloudinary.config.cloud_name.inspect}"
  puts "api_key:     #{Cloudinary.config.api_key.inspect}"
  # Never print the secret itself — only whether it is present.
  puts "api_secret:  #{Cloudinary.config.api_secret.nil? ? 'MISSING' : 'present'}"

  missing = REQUIRED_KEYS.select { |key| Cloudinary.config.send(key).nil? }
  raise "Cloudinary is not configured (missing: #{missing.join(', ')})" if missing.any?

  # URL generation needs only cloud_name and proves configuration is wired up.
  puts "Sample URL:  #{Cloudinary::Utils.cloudinary_url('sample')}"
  puts "Configuration OK."
end

begin
  main
rescue StandardError => e
  warn e.message
  warn "Set CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>"
  exit 1
end
