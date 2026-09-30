# Upload with CarrierWave

## When to use

You already use [CarrierWave](https://github.com/carrierwaveuploader/carrierwave) for
model attachments and want Cloudinary as the storage backend, with named versions
processed as delivery transformations instead of local ImageMagick work.

For new Rails applications, prefer
[Active Storage](upload-with-activestorage.md) — it is part of Rails and needs no extra
dependency.

> **CarrierWave is not a dependency of this gem.** Add `carrierwave` to your own Gemfile;
> this gem only provides the storage adapter, which loads when `CarrierWave` is defined.

## Setup

```ruby
# Gemfile
gem "carrierwave"
gem "cloudinary"
```

Credentials come from `CLOUDINARY_URL` — see
[Configure Cloudinary](configure-cloudinary.md). No `CarrierWave.configure` storage block
is needed; including the module sets the storage engine.

## Complete flow

```ruby
# app/uploaders/image_uploader.rb
class ImageUploader < CarrierWave::Uploader::Base
  include Cloudinary::CarrierWave

  process tags: ["photo-album"]
  process convert: "jpg"

  version :thumbnail do
    eager                                   # generate at upload time, not on first request
    resize_to_fit(150, 150)
    cloudinary_transformation quality: 80
  end
end
```

```ruby
class Photo < ApplicationRecord
  mount_uploader :image, ImageUploader
end
```

```ruby
photo = Photo.create!(image: File.open("sample.jpg"))

photo.image.url                # delivery URL of the stored asset
photo.image.thumbnail.url      # the 150x150 version
photo.image.public_id          # Cloudinary public_id
```

## Versions are transformations, not files

A `version` block does not produce a second stored file. It names a set of Cloudinary
transformation parameters, and `.url` for that version returns a derived delivery URL.
Consequences worth knowing:

- Adding or changing a version does **not** require reprocessing existing records — the
  next request delivers the new URL.
- Without `eager`, the derived asset is created by Cloudinary on the first request to that
  URL. `eager` moves that cost to upload time.

Processing DSL available inside a version: `resize_to_limit`, `resize_to_fit`,
`resize_to_fill`, `resize_and_pad`, `scale`, `crop`, `convert`, `tags`,
`cloudinary_transformation` (any transformation options), `make_private`, `eager`,
`upload_params`.

## Attaching a remote URL

`Cloudinary::CarrierWave::Remote` supports CarrierWave's `remote_<field>_url` pattern, so
Cloudinary fetches the source directly rather than proxying it through your server.

## Troubleshooting

- `uninitialized constant CarrierWave` — the `carrierwave` gem is not in your Gemfile;
  this gem does not pull it in.
- Versions render the original, untransformed image — the `version` block has no
  processing directives, or you called `.url` on the parent rather than the version.
- Local processing errors mentioning ImageMagick or MiniMagick — a standard CarrierWave
  processor is being used instead of the Cloudinary DSL. Inside
  `include Cloudinary::CarrierWave`, use the methods listed above.
- Uploads succeed but URLs 404 — the stored identifier includes a version; ensure you
  render `photo.image.url` rather than assembling a URL from the filename.

## Related

- Runnable example: `examples/upload-with-carrierwave.rb`
- [Use with Rails](use-with-rails.md)
- [Upload with Active Storage](upload-with-activestorage.md)
- [CarrierWave guide](https://cloudinary.com/documentation/rails_carrierwave.md)
