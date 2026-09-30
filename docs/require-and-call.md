# Require and call the SDK

```ruby
require "cloudinary"

Cloudinary::Uploader.upload("photo.jpg")          # upload and other write operations
Cloudinary::Api.resource("photo")                 # Admin API: read and manage assets
Cloudinary::Utils.cloudinary_url("photo")         # build a delivery URL (local, no network)
Cloudinary::Search.expression("...").execute      # Search API
```

Require once; every entry point is a module function on one of these four classes. There
is no client object to instantiate — configuration is process-global, read from
`CLOUDINARY_URL` on first use ([details](configure-cloudinary.md)).

Calls are **synchronous** and return a `Hash` (`Cloudinary::Api` returns a
`Cloudinary::Api::Response`, a `Hash` subclass that also exposes rate-limit headers).
Read result fields with string keys:

```ruby
result = Cloudinary::Uploader.upload("photo.jpg")
result["public_id"]   # string keys, not symbols
```

Options are passed as trailing keyword-style hash arguments:

```ruby
Cloudinary::Uploader.upload("photo.jpg", public_id: "photos/hero", overwrite: true)
```

## In Rails

Requiring is automatic — the gem hooks into Rails through a railtie, which also makes the
view helpers (`cl_image_tag`, `cl_video_tag`) available in templates. See
[Use with Rails](use-with-rails.md).

## Related

- [Configure Cloudinary](configure-cloudinary.md)
- [Ruby on Rails SDK guide](https://cloudinary.com/documentation/rails_integration.md)
