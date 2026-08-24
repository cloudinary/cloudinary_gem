# Transform and deliver an image

## When to use

Generate CDN-backed delivery URLs that resize, crop, overlay, or optimize an image. URL
generation is local — no network call, no secret required — and the derived asset is
created by Cloudinary on first request, then served from CDN cache.

For video, see [Transform and deliver a video](transform-and-deliver-video.md).

## Optimized image URL

```ruby
require "cloudinary" # only cloud_name is needed for URL generation

# 'sample' ships with every new Cloudinary account; substitute any public_id you own
thumbnail_url = Cloudinary::Utils.cloudinary_url(
  "sample",
  width: 200,
  height: 200,
  crop: "thumb",
  gravity: "auto",       # focus on the most interesting region; use "face" for people photos
  fetch_format: "auto",  # f_auto: best format for the requesting browser
  quality: "auto"        # q_auto: perceptual quality tuning
)
puts thumbnail_url
# https://res.cloudinary.com/<cloud>/image/upload/c_thumb,f_auto,g_auto,h_200,q_auto,w_200/sample
```

URLs are **HTTPS by default** — no `secure: true` needed. Pass `secure: false` for
`http://`.

In a Rails view, `cl_image_tag` takes the same options and renders a full `<img>` tag;
see [Use with Rails](use-with-rails.md).

## Chained transformations (order matters)

Each component runs on the output of the previous one. Pass an array to `transformation:`:

```ruby
# A text overlay needs no second asset; to overlay an image instead, pass
# overlay: "<public_id of an image in your account>".
banner_url = Cloudinary::Utils.cloudinary_url(
  "sample",
  transformation: [
    { width: 1280, height: 720, crop: "fill", gravity: "auto" },
    {
      overlay: { font_family: "Arial", font_size: 64, font_weight: "bold", text: "SALE" },
      color: "white",
      gravity: "south_east",
      x: 24,
      y: 24
    },
    { fetch_format: "auto", quality: "auto" }
  ]
)
puts banner_url
# .../image/upload/c_fill,g_auto,h_720,w_1280/co_white,g_south_east,l_text:Arial_64_bold:SALE,x_24,y_24/f_auto,q_auto/sample
```

Reordering components changes the output. When matching eagerly generated versions, the
serialized transformation string must match exactly.

## Generative editing on delivery

Server-supported generative transformations (background removal, generative fill, and
similar) can be expressed as transformation strings — this gem serializes them
generically via `effect:` or `raw_transformation:`, without dedicated typed builders:

```ruby
Cloudinary::Utils.cloudinary_url("sample", effect: "background_removal")
# .../image/upload/e_background_removal/sample
```

Their availability is account- and plan-dependent; verify against
https://cloudinary.com/documentation/generative_ai_transformations.md before relying on one.

## Cache behavior

- The same URL is served from CDN cache; a new transformation means a new URL.
- To bust stale caches after re-uploading the same `public_id`, deliver with the asset
  `version` from the upload response:

```ruby
Cloudinary::Utils.cloudinary_url(result["public_id"], version: result["version"])
# .../image/upload/v1787584957/examples/uploaded-sample
```

## Behaviour worth knowing

- Generated URLs carry an `?_a=` SDK-analytics parameter. It does not affect delivery or
  caching; pass `analytics: false` to omit it.
- A `public_id` containing a slash with no known version gets a `/v1/` placeholder
  segment (`.../image/upload/v1/folder/name.jpg`). This is expected and delivers
  correctly; pass the real `version` when you have it.

## Troubleshooting

- `Must supply cloud_name in tag or in configuration` — URL building still needs a
  `cloud_name`; see [Configure Cloudinary](configure-cloudinary.md).
- 401 on a delivery URL from a freshly provisioned cloud — delivery is IP-locked until
  the cloud is claimed, not a URL problem. See [Get Cloudinary credentials](get-credentials.md).
- 404 on a URL that looks right — the `public_id` does not exist, or it was uploaded as a
  different `resource_type`. An asset uploaded as `raw` is not deliverable as an image.

## Related

- Runnable example: `examples/transform-and-deliver-image.rb`
- [Transform and deliver a video](transform-and-deliver-video.md)
- Every transformation parameter and its accepted values:
  [Transformation reference](https://cloudinary.com/documentation/transformation_reference.md)
- [Image manipulation guide](https://cloudinary.com/documentation/rails_image_manipulation.md)
