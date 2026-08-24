# Upload a file through the bundled Cloudinary Active Storage service.
#
# Active Storage is a Rails component: the Cloudinary service patches ActiveStorage::Blob,
# so it needs the Rails engine loaded. This script boots the minimum Rails pieces
# (no database, no app directory) so it runs standalone. In a real application you do none
# of this — you declare the service in config/storage.yml:
#
#   cloudinary:
#     service: Cloudinary
#     secure: true
#
# set config.active_storage.service = :cloudinary, and attach files with
# has_one_attached / has_many_attached.
#
# Prerequisites: CLOUDINARY_URL must be set, and the rails gem available.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby upload-with-activestorage.rb
#
# Docs: ../docs/upload-with-activestorage.md

require "cloudinary"
require "open-uri"

begin
  require "rails"
  require "active_model/railtie"
  require "active_job/railtie"
  require "active_record/railtie"
  require "action_view/railtie"
  require "active_storage/engine"
rescue LoadError => e
  warn "Rails with Active Storage is required for this example: #{e.message}"
  exit 1
end

# A minimal Rails application: enough for the Active Storage engine to initialize.
# Active Storage models are Active Record models, so a database must be configured —
# in-memory SQLite keeps this script self-contained.
SERVICE_CONFIGURATIONS = {
  "cloudinary" => { "service" => "Cloudinary", "secure" => true }
}.freeze

class ExampleApp < Rails::Application
  config.eager_load = false
  # Deliberately not setting config.active_storage.service here: that would resolve the
  # service during boot, before ActiveStorage::Blob exists for the Cloudinary service to
  # extend. A real application sets it in config/environments/*.rb, by which point the
  # engine has finished loading.
  config.active_storage.service_configurations = SERVICE_CONFIGURATIONS
end

# Active Storage models are Active Record models, so a database must be configured.
# In-memory SQLite keeps this script self-contained; no tables are needed because the
# storage service is exercised directly.
ENV["DATABASE_URL"] = "sqlite3::memory:"

Rails.application.initialize!

# Now that the engine has loaded, ActiveStorage::Blob exists and the Cloudinary service
# can patch it. Rails autoloads this from the gem in a normal application.
require "active_storage/service/cloudinary_service"

SAMPLE_URL = "https://res.cloudinary.com/demo/image/upload/sample.jpg".freeze
LOCAL_PATH = "as-sample.jpg".freeze

def ensure_file_exists
  return LOCAL_PATH if File.exist?(LOCAL_PATH)

  URI.parse(SAMPLE_URL).open { |remote| File.binwrite(LOCAL_PATH, remote.read) }
  LOCAL_PATH
end

def main
  service = ActiveStorage::Service.configure(
    :cloudinary, SERVICE_CONFIGURATIONS
  )

  # Active Storage addresses assets by an opaque key, which becomes the Cloudinary
  # public_id (prefixed by `folder` if one is configured).
  key = ActiveStorage::BlobKey.new(key: "examples-activestorage-sample", filename: "sample")

  path = ensure_file_exists
  service.upload(key, Pathname.new(path), content_type: "image/jpeg")
  puts "Uploaded with key: #{key}"
  puts "Exists?  #{service.exist?(key)}"
  puts "URL:     #{service.url(key)}"
rescue ActiveStorage::IntegrityError => e
  # The service converts Cloudinary failures into the standard Active Storage error.
  warn "Attachment rejected: #{e.message}"
  exit 1
end

begin
  main
rescue StandardError => e
  warn "Active Storage upload failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
