# Upload an image

## When to use

Server-side upload of a local file, `IO`, remote URL, or data URI into your Cloudinary
product environment. For uploads started in a browser, see
[Sign a browser upload](sign-browser-upload.md).

## Complete flow

```ruby
require "cloudinary" # reads CLOUDINARY_URL

result = Cloudinary::Uploader.upload(
  "https://res.cloudinary.com/demo/image/upload/sample.jpg", # path, URL, data URI, or IO
  public_id: "examples/uploaded-sample", # stable, addressable ID; omit for a random one
  overwrite: true
)

puts result["public_id"]  # "examples/uploaded-sample"
puts result["secure_url"] # canonical HTTPS delivery URL of the original
puts result["width"], result["height"], result["format"], result["bytes"]
```

Result keys are **strings**, not symbols.

`Cloudinary::Uploader.upload` accepts a local path, a `Pathname`, an open `IO`/`File`, a
remote URL, or a `data:` URI. There is no separate stream method — pass the `IO`.

## Re-uploading the same public_id

Uploading to a `public_id` that already exists **replaces the asset by default** and
keeps the same `asset_id`. The delivery URL stays the same, so add the returned `version`
to bust CDN caches — see [Transform and deliver an image](transform-and-deliver-image.md).

`overwrite: false` does **not** raise. It leaves the stored asset untouched and returns
the existing asset's metadata with an extra `existing => true` key — so a "skip if
present" flow must check that key rather than rely on an exception:

```ruby
result = Cloudinary::Uploader.upload(source, public_id: "examples/uploaded-sample", overwrite: false)
puts "already present, not replaced" if result["existing"]
```

## Result fields to keep

Store `asset_id`. It never changes; `public_id` changes when an asset is renamed or moved.

```ruby
puts result["asset_id"] # e.g. "abcdef0123456789abcdef0123456789"
```

Look assets up with `Cloudinary::Api.resource_by_asset_id` (or
`resources_by_asset_ids`, `restore_by_asset_ids`, `delete_resources_by_asset_ids` in
bulk). Every lookup returns the `public_id` you need for delivery URLs and updates.

Asset-id variants do **not** exist for `Cloudinary::Api.update`, any `Cloudinary::Uploader`
method, or URL building. The reliable pattern is to look the asset up by `asset_id`, then
read `public_id` off the response for those calls.

## Size limits

Two separate limits apply, and they fail the same way:

- **100 MB per request.** A single `upload` call cannot exceed this, whatever your plan.
  Above it, use [`upload_large`](upload-large-video.md) — it splits the file into chunks
  (20 MB by default, set with `chunk_size`) and uploads them sequentially.
- **Your product environment's maximum asset size**, which varies by plan and is
  unrelated to the per-request ceiling. `upload_large` does not raise it.

Read the real values for your environment rather than assuming:

```ruby
limits = Cloudinary::Api.usage["media_limits"]
puts limits["image_max_size_bytes"]
puts limits["video_max_size_bytes"]
puts limits["image_max_px"], limits["asset_max_total_px"]
```

If an asset exceeds the environment maximum, chunking will not help — compress or resize
it before uploading, or upgrade the plan.

## Troubleshooting

- `Must supply api_key` — configuration missing; see [Configure Cloudinary](configure-cloudinary.md).
- `File size too large` — see [Size limits](#size-limits); either the request exceeded
  the 100 MB single-request ceiling, or the asset exceeds your product environment's
  maximum.
- `Resource not found - <url>` — the remote URL must be publicly reachable from
  Cloudinary. This is raised as `CloudinaryException`, not a 404-typed class.
- An upload you expected to fail overwrote an existing asset — `overwrite` defaults to
  true; see [Re-uploading the same public_id](#re-uploading-the-same-public_id).

## Related

- Runnable example: `examples/upload-image.rb`
- [Transform and deliver an image](transform-and-deliver-image.md)
- [Upload guide](https://cloudinary.com/documentation/rails_image_and_video_upload.md)
