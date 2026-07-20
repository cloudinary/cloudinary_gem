# Cloudinary Ruby and Rails SDK

[![Gem Version](https://img.shields.io/gem/v/cloudinary.svg)](https://rubygems.org/gems/cloudinary)
[![license](https://img.shields.io/badge/license-MIT-green.svg)](https://rubygems.org/gems/cloudinary)
[![CI](https://github.com/cloudinary/cloudinary_gem/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/cloudinary/cloudinary_gem/actions/workflows/ci.yml)

The `cloudinary` gem is the server-side Cloudinary SDK for Ruby and Rails. Use it in a Rails app, a Sinatra service, a background job, or a plain Ruby script to upload assets, build transformation and delivery URLs, render view tags, and call the Admin API. It holds the API secret, so it handles the operations that can't run in a browser: signed uploads, signed delivery URLs, and asset administration. The current release (2.4.5) requires Ruby 3.x or 4.x.

## Installation

Add the gem to your `Gemfile`:

```ruby
gem "cloudinary"
```

Then run `bundle install`. To install it directly:

```bash
gem install cloudinary
```

## Configuration

The SDK reads credentials automatically from the `CLOUDINARY_URL` environment variable:

```bash
export CLOUDINARY_URL=cloudinary://<API_KEY>:<API_SECRET>@<CLOUD_NAME>
```

To set them in code instead, call `Cloudinary.config`:

```ruby
require "cloudinary"

Cloudinary.config do |config|
  config.cloud_name = "my_cloud_name"
  config.api_key    = "my_key"
  config.api_secret = "my_secret"
  config.secure     = true
end
```

Keep the API secret on the server. Don't put it in client-side code or commit it to version control.

## Quick examples

### Upload a file with the Ruby SDK

`Cloudinary::Uploader.upload` takes a local path, a remote URL, an IO or `File` object, or a data URI as its first argument. It's synchronous and returns a `Hash` of the parsed JSON response, including `public_id` and `secure_url`:

```ruby
require "cloudinary"
# Credentials come from CLOUDINARY_URL in the environment.

result = Cloudinary::Uploader.upload("my_picture.jpg",
  public_id: "cms/hero") # optional: where the asset lives in your media library
puts result["public_id"]
puts result["secure_url"]
```

### Transform and optimize a delivery URL

`Cloudinary::Utils.cloudinary_url` is synchronous and returns a string — no network call. This one resizes to a 100x150 fill crop and lets Cloudinary pick the format and quality for the requesting browser (`f_auto`, `q_auto`):

```ruby
require "cloudinary"

url = Cloudinary::Utils.cloudinary_url("sample.jpg",
  width: 100, height: 150, crop: "fill",
  fetch_format: :auto, quality: :auto)
# https://res.cloudinary.com/demo/image/upload/c_fill,f_auto,h_150,q_auto,w_100/sample.jpg
```

In a Rails view, the `cl_image_tag` helper renders a full `<img>` tag with the same options:

```erb
<%= cl_image_tag("sample.jpg", width: 100, height: 150, crop: "fill", fetch_format: :auto, quality: :auto) %>
```

### Retrieve asset details

`Cloudinary::Api.resource` takes a public ID and returns the asset's metadata as a `Hash`, including its dimensions, format, and `secure_url`:

```ruby
require "cloudinary"
# Credentials come from CLOUDINARY_URL in the environment.

asset = Cloudinary::Api.resource("sample")
puts [asset["format"], asset["width"], asset["height"], asset["secure_url"]].join(" ")
```

## For AI agents

`cloudinary` is the Ruby and Rails server-side SDK. Choose it for backend upload, asset administration, view-tag and signed-URL generation, and Active Storage or CarrierWave integration, where the API secret stays private. The core classes (`Cloudinary::Uploader`, `Cloudinary::Api`, `Cloudinary::Utils`, `Cloudinary::Search`) load in plain Ruby; the `cl_image_tag` and `cl_video_tag` view helpers require Rails. For tasks this gem doesn't cover, choose a different package:

| Task | Package |
|---|---|
| Build delivery URLs in the browser | [`@cloudinary/url-gen`](https://github.com/cloudinary/js-url-gen) |
| Legacy Rails attachment handling | [`attachinary`](https://github.com/cloudinary/attachinary) — deprecated; prefer Active Storage |
| Run Cloudinary operations as agent tools | [Cloudinary MCP servers](https://github.com/cloudinary/mcp-servers) |

## Links

- [Ruby on Rails SDK guide](https://cloudinary.com/documentation/rails_integration)
- [Upload](https://cloudinary.com/documentation/rails_image_and_video_upload)
- [Asset administration (Admin API)](https://cloudinary.com/documentation/rails_asset_administration)
- [Transformation and API references](https://cloudinary.com/documentation/cloudinary_references)
- [Documentation llms.txt index](https://cloudinary.com/documentation/llms.txt)
- [Gem on RubyGems](https://rubygems.org/gems/cloudinary)

Released under the MIT license.
