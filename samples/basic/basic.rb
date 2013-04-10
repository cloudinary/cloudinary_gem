require 'rubygems'
require 'bundler/setup'

require 'cloudinary'
require 'cloudinary/uploader'
require 'cloudinary/utils'

require './config'

if Cloudinary.config.api_key.blank?
  puts
  puts "Please configure this demo to use your Cloudinary account"
  puts "by copying configuration values from the Management Console"
  puts "at https://cloudinary.com/console into config.rb."
  puts
  exit
end

puts "* Uploading sample image files, please wait..."

uploads = {}

# public_id for the upload will be generated on Cloudinary's backend.
uploads[:pizza] = Cloudinary::Uploader.upload "pizza.jpg",
  :tags => "basic_sample"

# Same image, uploaded with a public_id
uploads[:pizza2] = Cloudinary::Uploader.upload "pizza.jpg",
  :tags => "basic_sample", 
  :public_id => "my_favorite_pizza"

# Eager transformations are applied as soon as the file is uploaded,
# instead of lazily applying them when accessed by your site's visitors.
eager_options = {
  :width => 200, :height => 150, :crop => "scale", :format => "jpg"
}
uploads[:lake] = Cloudinary::Uploader.upload "lake.jpg",
  :tags => "basic_sample",
  :public_id => "blue_lake",
  # "eager" parameter accepts a list (or just a single item). You can pass
  # names of named transformations or just transformation parameters as we do here.  
  :eager => eager_options 

# In the two following examples, the file is fetched from a remote URL and stored in Cloudinary.
# This allows you to apply transformations and take advantage of Cloudinary's CDN layer.

uploads[:couple] = Cloudinary::Uploader.upload "http://res.cloudinary.com/demo/image/upload/couple.jpg",
  :tags => "basic_sample"

# Here, the transformation is applied to the uploaded image BEFORE storing it on the cloud.
# The original uploaded image is discarded.
uploads[:couple2] = Cloudinary::Uploader.upload "http://res.cloudinary.com/demo/image/upload/couple.jpg",
  :tags => "basic_sample",
  :width => 500,
  :height => 500,
  :crop => "fit",
  :effect => "saturation:-70"

puts "* Done."

puts
puts "* #{uploads.length} images were uploaded and are now available in the cloud."
uploads.each_value.with_index do |upload, index|
  puts "> Upload \##{index+1}:"
  puts "  Public ID: #{upload['public_id']}"
  puts "  URL: #{upload['url']}"
end

puts
puts "* Sample URLs of transformations on uploaded files:"

puts "> Fill 200x150"
puts "  " + Cloudinary::Utils.cloudinary_url(uploads[:pizza]["public_id"],
  :width => 200, :height => 150, :crop => "fill", :format => "jpg")

puts "> Fit into 200x150"
puts "  " + Cloudinary::Utils.cloudinary_url(uploads[:pizza2]["public_id"],
  :width => 200, :height => 150, :crop => "fit", :format => "jpg")

puts "> Eager transformation of scaling to 200x150"
puts "  " + Cloudinary::Utils.cloudinary_url(uploads[:lake]["public_id"],
  eager_options)

puts "> Face detection based 200x150 thumbnail"
puts "  " + Cloudinary::Utils.cloudinary_url(uploads[:couple]["public_id"],
  :width => 200, :height => 150, :crop => "thumb", :gravity => "faces", :format => "jpg")

puts "> Fill 200x150, round corners, apply the sepia effect"
puts "  " + Cloudinary::Utils.cloudinary_url(uploads[:couple2]["public_id"],
  :width => 200, :height => 150, :crop => "fill", :gravity => "face", :radius => 10, :effect => "sepia", :format => "jpg")

puts
puts "* That's it. You can now open the above URLs in the browser"
puts "* and check out the resultant images."
