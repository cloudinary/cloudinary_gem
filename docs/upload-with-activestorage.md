# Upload with Active Storage

## When to use

You want file attachments on Active Record models (`has_one_attached`,
`has_many_attached`) stored in Cloudinary. This gem ships an Active Storage service, so
Cloudinary becomes a storage backend like S3 or GCS.

Choose this over [CarrierWave](upload-with-carrierwave.md) for new Rails applications —
Active Storage is part of Rails and needs no extra dependency.

## Setup

Declare the service in `config/storage.yml`. The service name is `Cloudinary`:

```yaml
cloudinary:
  service: Cloudinary
  secure: true
```

Point the environment at it:

```ruby
# config/environments/production.rb
config.active_storage.service = :cloudinary
```

Credentials come from `CLOUDINARY_URL` as usual — see
[Configure Cloudinary](configure-cloudinary.md).

Any additional keys in the `storage.yml` entry are passed through as upload options, so
you can set defaults for every attachment:

```yaml
cloudinary:
  service: Cloudinary
  secure: true
  folder: my-app-uploads    # prefix every public_id
  tags:
    - production
```

## Complete flow

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos
end
```

```ruby
user = User.create!(name: "Ada")
user.avatar.attach(
  io: File.open("avatar.jpg"),
  filename: "avatar.jpg",
  content_type: "image/jpeg"
)

user.avatar.attached?  # => true
user.avatar.key        # the Active Storage key; also the Cloudinary public_id
```

In a view, the Cloudinary helpers accept the attachment directly and apply
transformations:

```erb
<%= cl_image_tag(user.avatar.key, width: 200, height: 200, crop: "fill", gravity: "face") %>
```

## How assets are stored

- The Active Storage **key becomes the Cloudinary `public_id`**, prefixed by `folder` if
  you configured one. Keys are random, so public IDs are not human-readable — that is
  Active Storage's model, not a Cloudinary limitation.
- `resource_type` is derived from the content type: images as `image`, video as `video`,
  everything else as `raw`.
- **Raw files keep their extension in the public ID**, because that is how Cloudinary
  addresses raw assets.
- Uploads go through `upload_large`, so large attachments are chunked automatically.

## Errors

The service converts Cloudinary failures into
`ActiveStorage::IntegrityError`, matching what other Active Storage services raise:

```ruby
begin
  user.avatar.attach(io: io, filename: "big.mp4", content_type: "video/mp4")
rescue ActiveStorage::IntegrityError => e
  warn "Attachment rejected: #{e.message}"
end
```

## Variants and transformations

Do **not** use Active Storage `variant` processing (`avatar.variant(resize_to_limit:)`)
with this service — that pipeline expects local image processing via ImageMagick/Vips and
defeats the point of a transformation CDN. Build a Cloudinary URL instead:

```erb
<%= cl_image_tag(user.avatar.key, width: 400, crop: "fill", fetch_format: "auto", quality: "auto") %>
```

## Load order (only matters outside a normal Rails boot)

The service extends `ActiveStorage::Blob`, so it can only load **after** the Active
Storage engine has initialized. In a standard application this is automatic: Rails loads
the engine, then reads `config.active_storage.service` from
`config/environments/*.rb`.

It only breaks if you resolve the service during application boot — for example setting
`config.active_storage.service` inside the `Rails::Application` class body in a script.
That raises `uninitialized constant ActiveStorage::Blob`. Keep the assignment in an
environment file, as Rails generates it.

## Troubleshooting

- `Cannot load service :cloudinary` — `service: Cloudinary` must be capitalised exactly;
  it names the service class, not a lowercase adapter key.
- `uninitialized constant ActiveStorage::Blob` — the service was resolved before the
  engine finished loading. See [Load order](#load-order-only-matters-outside-a-normal-rails-boot).
- Attachments upload but URLs 404 — the environment's
  `config.active_storage.service` points at a different entry than the one you configured.
- Raw file URL 404s without the extension — expected; raw public IDs include the
  extension. Use the key the service returns.
- Attachment succeeds but the asset is `raw` when you expected `image` — the
  `content_type` passed to `attach` was generic (for example
  `application/octet-stream`). Pass the real content type.

## Related

- Runnable example: `examples/upload-with-activestorage.rb`
- [Use with Rails](use-with-rails.md)
- [Upload with CarrierWave](upload-with-carrierwave.md)
- [Active Storage guide](https://cloudinary.com/documentation/rails_activestorage.md)
