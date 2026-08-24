# Upload a large video

## When to use

Any upload over ~100 MB, or any video where you want chunked transfer that tolerates
network interruptions.

## Complete flow

`Cloudinary::Uploader.upload_large` is synchronous and returns the upload result
directly. The one thing you must not omit is `resource_type`:

```ruby
require "cloudinary" # reads CLOUDINARY_URL

result = Cloudinary::Uploader.upload_large(
  "dog.mp4",
  resource_type: :video,       # REQUIRED for video: upload_large defaults to :raw
  chunk_size: 20_000_000,      # 20 MB is the default; 5 MB is the accepted minimum
  public_id: "examples/uploaded-large-video",
  overwrite: true
)

puts result["public_id"]     # "examples/uploaded-large-video"
puts result["resource_type"] # "video"
puts result["duration"]      # 13.4134
puts result["bytes"]
puts result["secure_url"]    # playback URL
puts result["done"]          # true when the final chunk was accepted
```

## resource_type is not optional

This is the most consequential mistake with `upload_large`, because **nothing fails**:

```ruby
# WRONG — no resource_type
result = Cloudinary::Uploader.upload_large("dog.mp4", chunk_size: 5_500_000)
result["resource_type"] # => "raw"
result["public_id"]     # => "....mp4"  (extension becomes part of the ID)
result["duration"]      # => nil        (never probed)
```

The upload succeeds and stores an opaque blob. No video transformation, thumbnail,
streaming profile, or poster frame will ever work on it, and the failure surfaces much
later as a transformation error on an unrelated page. Always pass
`resource_type: :video` (or `:image` / `:auto` as appropriate).

## Chunking behaviour

- Files **smaller than `chunk_size` are delegated to a normal single-request upload**, so
  a small file works fine through this method.
- A **remote URL** is also delegated to a single `upload` call — chunking only applies to
  local files and `IO` objects.
- `chunk_size` below the 5 MB service minimum is rejected for multi-chunk uploads.

## Asynchronous processing

Large or busy videos may finish **processing** after the upload completes. For derived
versions, pass `eager` transformations with `eager_async: true` and a `notification_url`
webhook; the response then includes a pending status until Cloudinary calls your webhook.

## Troubleshooting

- Missing `resource_type: :video` — the asset lands as `raw` and cannot be transformed or
  streamed. See [above](#resource_type-is-not-optional).
- `All parts except EOF-chunk must be larger than 5mb` — `chunk_size` is below the 5 MB
  minimum.
- Timeouts on slow links — reduce `chunk_size`; each chunk is a separate request.
- `Must supply api_key` — configuration missing; see [Configure Cloudinary](configure-cloudinary.md).

## Related

- Runnable example: `examples/upload-large-video.rb` — works with no arguments; it
  downloads a sample video from the Cloudinary demo account if none is present.
- [Transform and deliver a video](transform-and-deliver-video.md) — what to do with it
  once it is uploaded.
- [Video upload guide](https://cloudinary.com/documentation/rails_image_and_video_upload.md)
