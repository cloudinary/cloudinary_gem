# Generate a signature that authorizes a browser to upload directly to Cloudinary.
#
# The api_secret stays on the server; the browser receives only the signature, the
# timestamp, the api_key, and the cloud_name. Signatures are valid for 1 hour.
#
# Prerequisites: CLOUDINARY_URL must be set.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby sign-browser-upload.rb
# In your own project: require "cloudinary"
#
# Docs: ../docs/sign-browser-upload.md

require "cloudinary"
require "json"

UPLOAD_FOLDER = "user-uploads".freeze

# What a signing endpoint would return to the browser.
def signing_payload
  timestamp = Time.now.to_i

  # Sign ONLY the parameters the client is allowed to send. Every parameter the browser
  # sends (except file, api_key, signature, resource_type) must be signed here, or
  # Cloudinary rejects the upload with "Invalid Signature".
  params_to_sign = { timestamp: timestamp, folder: UPLOAD_FOLDER }

  {
    signature: Cloudinary::Utils.api_sign_request(params_to_sign, Cloudinary.config.api_secret),
    timestamp: timestamp,
    folder: UPLOAD_FOLDER,
    api_key: Cloudinary.config.api_key,
    cloud_name: Cloudinary.config.cloud_name
  }
end

def main
  raise "Must supply api_secret" if Cloudinary.config.api_secret.nil?

  payload = signing_payload
  puts JSON.pretty_generate(payload)
  puts
  puts "The browser POSTs file + these fields to:"
  puts "https://api.cloudinary.com/v1_1/#{payload[:cloud_name]}/auto/upload"
end

begin
  main
rescue StandardError => e
  warn "Signing failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
