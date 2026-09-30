# Define a CarrierWave uploader backed by Cloudinary and show the version URLs it builds.
#
# CarrierWave is NOT a dependency of this gem — add `gem "carrierwave"` to your own
# Gemfile. This script exits with a message if it is not installed.
#
# Prerequisites: CLOUDINARY_URL must be set, and the carrierwave gem available.
#   export CLOUDINARY_URL=cloudinary://<api_key>:<api_secret>@<cloud_name>
#
# Run: ruby upload-with-carrierwave.rb
# In your own project: mount_uploader :image, ImageUploader
#
# Docs: ../docs/upload-with-carrierwave.md

require "cloudinary"

begin
  require "carrierwave"
rescue LoadError
  warn "CarrierWave is not installed. Add `gem \"carrierwave\"` to your Gemfile."
  warn "This gem provides the Cloudinary storage adapter but does not depend on CarrierWave."
  exit 1
end

require "cloudinary/carrier_wave"

# A version block names a set of Cloudinary transformations. It does not create a second
# stored file — the derived asset is built on delivery (or at upload time with `eager`).
class ImageUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process convert: "jpg"

  version :thumbnail do
    eager
    resize_to_fit(150, 150)
    cloudinary_transformation quality: 80
  end
end

def main
  puts "Uploader:   #{ImageUploader}"
  puts "Storage:    #{ImageUploader.storage}"
  # `versions` lists the declared versions. (`version_names` is the chain of the *current*
  # uploader, so it is empty on the parent and [:thumbnail] on the version itself.)
  puts "Versions:   #{ImageUploader.versions.keys.inspect}"
  puts
  puts "In a model:  mount_uploader :image, ImageUploader"
  puts "Then:        photo.image.url"
  puts "             photo.image.thumbnail.url  # the 150x150 derived URL"
  puts
  # The equivalent delivery URLs, built directly:
  puts "Original:   #{Cloudinary::Utils.cloudinary_url('sample', format: 'jpg')}"
  puts "Thumbnail:  #{Cloudinary::Utils.cloudinary_url('sample',
                                                       format: 'jpg',
                                                       width: 150, height: 150,
                                                       crop: 'fit', quality: 80)}"
end

begin
  main
rescue StandardError => e
  warn "CarrierWave example failed: #{e.message}"
  warn "Check that CLOUDINARY_URL is set (Console > Settings > API Keys)."
  exit 1
end
